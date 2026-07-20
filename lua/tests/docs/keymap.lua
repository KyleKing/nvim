local function keymap_exists_test(name, lhs)
    return {
        name = name,
        expect = {
            fn = function(_ctx)
                local helpers = require("tests.helpers")
                local MiniTest = require("mini.test")
                local exists = helpers.check_keymap(lhs, "i")
                MiniTest.expect.equality(exists, true, lhs .. " insert-mode keymap should exist")
            end,
        },
    }
end

return {
    title = "Smart insert keys (mini.keymap)",
    see_also = { "MiniKeymap" },
    desc = "Multi-step Insert-mode keys that combine completion-menu control and mini.snippets expansion. Each step runs only when its condition holds, otherwise the literal key is inserted.",
    source = "lua/kyleking/deps/keymap.lua",

    notes = {
        "`<Tab>` Jump to next snippet tabstop, else expand a snippet, else literal Tab.",
        "`<S-Tab>` Jump to previous snippet tabstop, else literal S-Tab.",
        "`<C-j>` / `<C-k>` Select next / previous completion item (when the menu is open).",
        "`<C-CR>` Accept the selected completion item.",
        "`<CR>` Abort an open completion menu and insert a newline (acceptance is `<C-CR>`).",
        "",
        "Buffer-local `<Tab>`/`<CR>` maps (e.g. markdown/djot list editing) still take precedence where set.",
    },

    grammars = {
        {
            pattern = "<Tab> / <S-Tab>",
            desc = "Snippet expand and jump",
            tests = {
                keymap_exists_test("tab keymap exists", "<Tab>"),
                keymap_exists_test("shift-tab keymap exists", "<S-Tab>"),
            },
        },
        {
            pattern = "<C-j> / <C-k>",
            desc = "Completion menu navigation",
            tests = {
                keymap_exists_test("c-j keymap exists", "<C-j>"),
                keymap_exists_test("c-k keymap exists", "<C-k>"),
            },
        },
        {
            pattern = "<C-CR> / <CR>",
            desc = "Accept or abort completion",
            tests = {
                keymap_exists_test("c-cr keymap exists", "<C-CR>"),
                keymap_exists_test("cr keymap exists", "<CR>"),
            },
        },
    },
}
