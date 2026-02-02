-- Test complete LSP workflow
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["lsp workflow"] = MiniTest.new_set()

T["lsp workflow"]["LSP module loads"] = function()
    MiniTest.expect.no_error(function() require("kyleking.core.lsp") end)
end

T["lsp workflow"]["LSP keymaps are configured"] = function()
    vim.wait(1000)

    -- Check common LSP keymaps
    local check_keymap = function(lhs)
        local keymap = vim.fn.maparg(lhs, "n", false, true)
        return keymap ~= nil and keymap.lhs ~= nil
    end

    -- These should be set globally
    MiniTest.expect.equality(check_keymap("<leader>lr"), true, "<leader>lr (rename) should exist")
    MiniTest.expect.equality(check_keymap("<leader>la"), true, "<leader>la (actions) should exist")
end

T["lsp workflow"]["Diagnostic configuration exists"] = function()
    vim.wait(1000)

    local config = vim.diagnostic.config()
    MiniTest.expect.equality(type(config), "table", "Diagnostic config should be a table")
end

T["lsp workflow"]["Can format with conform"] = function()
    vim.wait(1000)

    local conform = require("conform")
    MiniTest.expect.equality(type(conform.format), "function", "conform.format should be callable")
end

T["lsp workflow"]["Can lint with nvim-lint"] = function()
    vim.wait(1000)

    local lint = require("lint")
    MiniTest.expect.equality(type(lint.try_lint), "function", "lint.try_lint should be callable")
end

T["lsp workflow"]["Trouble is available for diagnostics"] = function()
    vim.wait(1000)

    local trouble = require("trouble")
    MiniTest.expect.equality(type(trouble.toggle), "function", "trouble.toggle should be callable")
end

T["lsp workflow"]["LSP signature help is configured"] = function()
    vim.wait(1000)

    local signature = require("lsp_signature")
    MiniTest.expect.equality(type(signature.toggle_float_win), "function", "Signature help should be available")
end

T["lsp workflow"]["LSP pickers are available"] = function()
    vim.wait(1000)

    local MiniExtra = require("mini.extra")
    MiniTest.expect.equality(type(MiniExtra.pickers.lsp), "function", "LSP picker should be available")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
