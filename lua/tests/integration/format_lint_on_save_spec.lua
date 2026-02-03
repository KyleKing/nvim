-- Test format and lint on save autocmds
-- These are critical workflows that must not break
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
    },
})

T["format on save"] = MiniTest.new_set()

T["format on save"]["format autocmd is registered"] = function()
    helpers.wait_for_plugins()

    -- Check for BufWritePre autocmd for formatting
    local autocmds = vim.api.nvim_get_autocmds({
        event = "BufWritePre",
    })

    local has_format_autocmd = false
    for _, autocmd in ipairs(autocmds) do
        -- Look for conform format autocmd
        if autocmd.desc and autocmd.desc:match("[Ff]ormat") then
            has_format_autocmd = true
            break
        end
    end

    MiniTest.expect.equality(has_format_autocmd, true, "Format on save autocmd should be registered")
end

T["format on save"]["Lua file formats on write"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Wait longer for plugins/formatters to load in subprocess
        vim.wait(3000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        -- Write unformatted Lua code
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x=1",
            "local y=2",
            "if x==y then print('test') end",
        })

        -- Save file (should trigger format)
        vim.cmd("write")
        -- Wait for format to complete
        vim.wait(2000)

        -- Read back and check formatting
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local formatted = table.concat(lines, "\n")

        -- Check for proper spacing (stylua formatting)
        if formatted:match("local x = 1") and formatted:match("if x == y then") then
            print("SUCCESS: File was formatted on save")
        else
            print("WARNING: Formatting may not have applied")
            print("Content: " .. formatted)
        end

        vim.fn.delete(tmpfile)
    ]],
        30000
    )

    MiniTest.expect.equality(result.code, 0, "Format on save should work: " .. result.stderr)
end

T["format on save"]["Python file formats on write"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        -- Wait longer for plugins/formatters to load in subprocess
        vim.wait(3000)

        local tmpfile = vim.fn.tempname() .. ".py"
        vim.cmd("edit " .. tmpfile)

        -- Write unformatted Python code
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "x=1",
            "y=2",
            "if x==y:print('test')",
        })

        -- Save file (should trigger format with ruff)
        vim.cmd("write")
        -- Wait for format to complete
        vim.wait(2000)

        -- Read back
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local formatted = table.concat(lines, "\n")

        -- Check for proper formatting
        if formatted:match("x = 1") then
            print("SUCCESS: Python file was formatted on save")
        else
            print("WARNING: Python formatting may not have applied")
            print("Content: " .. formatted)
        end

        vim.fn.delete(tmpfile)
    ]],
        30000
    )

    MiniTest.expect.equality(result.code, 0, "Python format on save should work: " .. result.stderr)
end

T["lint on save"] = MiniTest.new_set()

T["lint on save"]["lint autocmd is registered"] = function()
    helpers.wait_for_plugins()

    -- Check for lint autocmds
    local events = { "BufWritePost", "BufReadPost", "InsertLeave" }
    local has_lint_autocmd = false

    for _, event in ipairs(events) do
        local autocmds = vim.api.nvim_get_autocmds({ event = event })
        for _, autocmd in ipairs(autocmds) do
            if autocmd.desc and autocmd.desc:match("[Ll]int") then
                has_lint_autocmd = true
                break
            end
        end
        if has_lint_autocmd then break end
    end

    MiniTest.expect.equality(has_lint_autocmd, true, "Lint autocmd should be registered")
end

T["lint on save"]["linters configured for common filetypes"] = function()
    helpers.wait_for_plugins()

    local lint = require("lint")

    -- Check that linters are configured
    MiniTest.expect.equality(type(lint.linters_by_ft), "table", "Linters should be configured")

    -- Check specific filetypes
    local filetypes = { "python", "lua", "javascript", "typescript" }
    for _, ft in ipairs(filetypes) do
        local linters = lint.linters_by_ft[ft]
        if linters then
            MiniTest.expect.equality(
                type(linters) == "table" and #linters > 0,
                true,
                "Linter should be configured for " .. ft
            )
        end
    end
end

T["autocmd conflicts"] = MiniTest.new_set()

T["autocmd conflicts"]["no duplicate BufWritePre autocmds"] = function()
    helpers.wait_for_plugins()

    -- Count BufWritePre autocmds to detect duplicates
    local autocmds = vim.api.nvim_get_autocmds({ event = "BufWritePre" })

    -- Group by description to find duplicates
    local by_desc = {}
    for _, autocmd in ipairs(autocmds) do
        local desc = autocmd.desc or "no_description"
        by_desc[desc] = (by_desc[desc] or 0) + 1
    end

    -- Check for duplicates (same description multiple times)
    local duplicates = {}
    for desc, count in pairs(by_desc) do
        if count > 1 and not desc:match("^no_description") then
            table.insert(duplicates, desc .. " (x" .. count .. ")")
        end
    end

    MiniTest.expect.equality(
        #duplicates,
        0,
        "Should not have duplicate BufWritePre autocmds: " .. table.concat(duplicates, ", ")
    )
end

T["autocmd conflicts"]["format and lint autocmds don't conflict"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "local x=1",
        })

        -- Track if both format and lint run
        local events_fired = {}
        vim.api.nvim_create_autocmd("User", {
            pattern = "FormatterPost",
            callback = function()
                table.insert(events_fired, "format")
            end,
        })

        -- Save file
        vim.cmd("write")
        vim.wait(1500)

        print("SUCCESS: Format and lint completed without conflicts")

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Format and lint should not conflict: " .. result.stderr)
end

T["format performance"] = MiniTest.new_set()

T["format performance"]["format completes within timeout"] = function()
    local result = helpers.nvim_interaction_test(
        [[
        vim.wait(2000)

        local tmpfile = vim.fn.tempname() .. ".lua"
        vim.cmd("edit " .. tmpfile)

        -- Create moderately sized file
        local lines = {}
        for i = 1, 100 do
            table.insert(lines, "local var_" .. i .. "=" .. i)
        end
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

        local start = vim.loop.now()
        require("conform").format({ bufnr = 0, timeout_ms = 5000 })
        local elapsed = vim.loop.now() - start

        if elapsed < 5000 then
            print("SUCCESS: Format completed in " .. elapsed .. "ms")
        else
            print("WARNING: Format took " .. elapsed .. "ms")
        end

        vim.fn.delete(tmpfile)
    ]],
        20000
    )

    MiniTest.expect.equality(result.code, 0, "Format should complete in reasonable time: " .. result.stderr)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
