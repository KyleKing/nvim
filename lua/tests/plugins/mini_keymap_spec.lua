-- Test mini.keymap smart insert-mode keys
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() helpers.wait_for_plugins() end,
    },
})

T["mini.keymap"] = MiniTest.new_set()

T["mini.keymap"]["smart insert maps are expression maps"] = function()
    for _, lhs in ipairs({ "<Tab>", "<S-Tab>", "<C-j>", "<C-k>", "<C-CR>", "<CR>" }) do
        local keymap = vim.fn.maparg(lhs, "i", false, true)
        MiniTest.expect.equality(keymap.lhs ~= nil, true, lhs .. " should be mapped")
        MiniTest.expect.equality(keymap.expr, 1, lhs .. " should be an expression map")
    end
end

T["mini.keymap"]["module and snippet integration points are wired"] = function()
    -- map_multistep drives the maps; its snippet steps rely on mini.snippets' session API
    MiniTest.expect.equality(type(require("mini.keymap").map_multistep), "function")
    local snippets = require("mini.snippets")
    MiniTest.expect.equality(type(snippets.session.get), "function", "session.get powers minisnippets steps")
    MiniTest.expect.equality(type(snippets.expand), "function", "expand powers minisnippets_expand step")
end

T["mini.keymap"]["CR is not overridden by a stale core/lsp buffer map"] = function()
    -- The completion CR/C-CR/C-j/C-k maps moved out of the LspAttach handler to global
    -- mini.keymap maps; confirm the global insert <CR> map is present and expr-driven
    local cr = vim.fn.maparg("<CR>", "i", false, true)
    MiniTest.expect.equality(cr.expr, 1, "<CR> should be an expression map from mini.keymap")
    MiniTest.expect.equality(cr.buffer, 0, "<CR> smart map should be global, not buffer-local")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
