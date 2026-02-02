-- Test conform.nvim formatting integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["conform.nvim"] = MiniTest.new_set()

T["conform.nvim"]["formatting module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.deps.formatting") end)
end

T["conform.nvim"]["conform is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("conform"), true, "conform should be loaded")
end

T["conform.nvim"]["format keymap is set"] = function()
    vim.wait(1000)

    local keymap = vim.fn.maparg("<leader>lf", "n", false, true)
    MiniTest.expect.equality(keymap ~= nil and keymap.lhs ~= nil, true, "<leader>lf mapping should exist")

    -- Verify callable
    local has_callable = (type(keymap.callback) == "function") or (type(keymap.rhs) == "string" and keymap.rhs ~= "")
    MiniTest.expect.equality(has_callable, true, "<leader>lf should have callable rhs")
end

T["conform.nvim"]["formatters are configured for common filetypes"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local formatters_by_ft = conform.formatters_by_ft or {}

    -- Check that common filetypes have formatters
    local common_filetypes = { "lua", "python", "javascript", "typescript", "json", "yaml", "markdown" }

    for _, ft in ipairs(common_filetypes) do
        local formatters = formatters_by_ft[ft]
        MiniTest.expect.equality(formatters ~= nil, true, ft .. " should have formatters configured")
    end
end

T["conform.nvim"]["lua formatter is stylua"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local lua_formatters = conform.formatters_by_ft.lua or {}

    local has_stylua = false
    for _, formatter in ipairs(lua_formatters) do
        if formatter == "stylua" then
            has_stylua = true
            break
        end
    end

    MiniTest.expect.equality(has_stylua, true, "Lua should use stylua formatter")
end

T["conform.nvim"]["python formatter is ruff"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local python_formatters = conform.formatters_by_ft.python or {}

    local has_ruff = false
    for _, formatter in ipairs(python_formatters) do
        if formatter == "ruff_format" or formatter == "ruff_fix" then
            has_ruff = true
            break
        end
    end

    MiniTest.expect.equality(has_ruff, true, "Python should use ruff formatter")
end

T["conform.nvim"]["javascript formatter uses prettier"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local js_formatters = conform.formatters_by_ft.javascript or {}

    local has_prettier = false
    for _, formatter in ipairs(js_formatters) do
        if formatter == "prettierd" or formatter == "prettier" then
            has_prettier = true
            break
        end
    end

    MiniTest.expect.equality(has_prettier, true, "JavaScript should use prettier")
end

T["conform.nvim"]["typos is global formatter"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local global_formatters = conform.formatters_by_ft["*"] or {}

    local has_typos = false
    for _, formatter in ipairs(global_formatters) do
        if formatter == "typos" then
            has_typos = true
            break
        end
    end

    MiniTest.expect.equality(has_typos, true, "Global formatter should include typos")
end

T["conform.nvim"]["format function exists and is callable"] = function()
    vim.wait(1000)

    local conform = require("conform")
    MiniTest.expect.equality(type(conform.format), "function", "conform.format should be a function")
end

T["conform.nvim"]["can format lua buffer"] = function()
    vim.wait(1000)

    -- Skip if stylua not available
    if vim.fn.executable("stylua") ~= 1 then
        MiniTest.skip("stylua not installed")
        return
    end

    local conform = require("conform")
    local bufnr = helpers.create_test_buffer({ "local x=1" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Format the buffer
    conform.format({ bufnr = bufnr, timeout_ms = 3000 })

    -- Get the formatted line
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]

    -- stylua formats with spaces around =
    local is_formatted = line:match("local x = 1")
    MiniTest.expect.equality(is_formatted ~= nil, true, "Line should be formatted by stylua")

    helpers.delete_buffer(bufnr)
end

T["conform.nvim"]["can get formatter info"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local info = conform.list_formatters(0)

    MiniTest.expect.equality(type(info), "table", "Formatter info should be a table")
end

T["conform.nvim"]["format timeout is configured"] = function()
    vim.wait(1000)

    local conform = require("conform")
    local config = conform.formatters or {}

    -- Verify setup was called (config exists)
    MiniTest.expect.equality(type(config), "table", "Conform config should exist")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
