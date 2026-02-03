return {
    title = "Clue (mini.clue)",
    see_also = { "MiniClue" },
    desc = "Displays available keybinding continuations after a 500ms delay.",
    source = "lua/kyleking/deps/keybinding.lua",

    notes = {
        "Triggers on `<Leader>`, `g`, `'`, `` ` ``, `\"`, `<C-r>`, `<C-w>`, `<C-x>`, `z`, `[`, `]`.",
        "",
        "**Tips**:",
        "- Scroll the clue window with `<C-d>` / `<C-u>`",
        "- Register clue shows register contents inline",
    },

    grammars = {
        {
            pattern = "<leader>",
            desc = "Show leader key continuations",
            tests = {
                {
                    name = "config check",
                    expect = {
                        fn = function(_ctx)
                            local MiniClue = require("mini.clue")
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(type(MiniClue.setup), "function")
                            MiniTest.expect.equality(type(MiniClue.config.triggers), "table")
                        end,
                    },
                },
            },
        },
    },
}
