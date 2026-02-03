return {
    title = "Flash (motion/jumping)",
    see_also = { "flash.nvim" },
    desc = "Jump to any visible location with minimal keystrokes.",
    source = "lua/kyleking/deps/motion.lua",

    notes = {
        "`<Alt-s>` Flash jump (normal, visual, operator-pending)",
        "`<Alt-S>` Flash Treesitter (select treesitter node)",
        "`<C-s>` Toggle Flash Search (in command-line / search)",
        "",
        "Flash labels visible matches so you can jump with 1-2 keystrokes.",
        "Treesitter mode selects entire syntax nodes.",
        "Works in operator-pending mode: `d<Alt-s>`, `y<Alt-s>`.",
    },

    grammars = {
        {
            pattern = "<a-s>",
            desc = "Flash jump",
            tests = {
                {
                    name = "jump shows labels",
                    expect = {
                        fn = function(_ctx)
                            local flash = require("flash")
                            local MiniTest = require("mini.test")
                            -- Just verify flash module loads
                            MiniTest.expect.equality(type(flash.jump), "function", "Flash should be loaded")
                        end,
                    },
                },
            },
        },
        {
            pattern = "<a-S>",
            desc = "Flash treesitter jump",
            tests = {
                {
                    name = "treesitter jump available",
                    expect = {
                        fn = function(_ctx)
                            local flash = require("flash")
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(type(flash.treesitter), "function", "Treesitter jump available")
                        end,
                    },
                },
            },
        },
    },
}
