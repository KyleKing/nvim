-- Test conform.nvim formatting integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["conform.nvim"] = MiniTest.new_set()

-- Behavioral test: actual formatting action
T["conform.nvim"]["can format lua buffer"] = function()
    if vim.fn.executable("stylua") ~= 1 then
        MiniTest.skip("stylua not installed")
        return
    end

    local conform = require("conform")
    local bufnr = helpers.create_test_buffer({ "local x=1" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    conform.format({ bufnr = bufnr, timeout_ms = 3000 })

    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local is_formatted = line:match("local x = 1")
    MiniTest.expect.equality(is_formatted ~= nil, true, "Line should be formatted by stylua")

    helpers.delete_buffer(bufnr)
end

-- Test dynamic formatter detection doesn't error (regression test for ctx type error)
T["conform.nvim"]["formatters_by_ft functions handle buffer numbers"] = function()
    local conform = require("conform")
    local filetypes = { "python", "javascript", "typescript", "go", "rust" }

    for _, ft in ipairs(filetypes) do
        local bufnr = helpers.create_test_buffer({ "test" }, ft)
        vim.api.nvim_set_current_buf(bufnr)

        local success, err = pcall(function()
            local formatters = conform.list_formatters(bufnr)
            MiniTest.expect.equality(type(formatters), "table", "Should return formatters list for " .. ft)
        end)

        MiniTest.expect.equality(
            success,
            true,
            "Should not error for filetype: " .. ft .. " (error: " .. tostring(err) .. ")"
        )
        helpers.delete_buffer(bufnr)
    end
end

-- Test <leader>lf keybinding doesn't error
T["conform.nvim"]["<leader>lf keybinding works"] = function()
    local bufnr = helpers.create_test_buffer({ "local x=1" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    local success, err = pcall(function() require("conform").format({ timeout_ms = 1000 }) end)

    MiniTest.expect.equality(success, true, "<leader>lf should not error (error: " .. tostring(err) .. ")")
    helpers.delete_buffer(bufnr)
end

-- Test formatters_by_ft returns valid formatter lists
T["conform.nvim"]["dynamic formatters return valid lists"] = function()
    local conform = require("conform")
    local test_cases = {
        { ft = "python", expected_default = { "ruff_format", "ruff_fix" } },
        { ft = "javascript", expected_default = { "prettierd", "prettier" } },
        { ft = "go", expected_default = { "gofmt" } },
        { ft = "rust", expected_default = { "rustfmt" } },
    }

    for _, tc in ipairs(test_cases) do
        local bufnr = helpers.create_test_buffer({ "test" }, tc.ft)
        local formatters = conform.list_formatters(bufnr)

        MiniTest.expect.equality(type(formatters), "table", "Should return table for " .. tc.ft)
        MiniTest.expect.equality(#formatters > 0, true, "Should have at least one formatter for " .. tc.ft)

        helpers.delete_buffer(bufnr)
    end
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
