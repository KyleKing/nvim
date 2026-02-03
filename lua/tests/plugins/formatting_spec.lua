-- Test conform.nvim formatting integration
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() vim.wait(1000) end,
    },
})

T["conform.nvim"] = MiniTest.new_set()

T["conform.nvim"]["formatters are configured for common filetypes"] = function()
    local conform = require("conform")
    local formatters_by_ft = conform.formatters_by_ft or {}

    local common_filetypes = { "lua", "python", "javascript", "typescript", "json", "yaml", "markdown" }

    for _, ft in ipairs(common_filetypes) do
        local formatters = formatters_by_ft[ft]
        MiniTest.expect.equality(formatters ~= nil, true, ft .. " should have formatters configured")
    end
end

T["conform.nvim"]["lua formatter is stylua"] = function()
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

-- For manual running
if ... == nil then MiniTest.run() end

return T
