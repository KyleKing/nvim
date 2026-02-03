return {
    title = "Flash Motion (flash.nvim)",
    see_also = { "flash.nvim" },
    desc = "Enhanced motion with labeled jump targets.",
    source = "lua/kyleking/deps/motion.lua",

    notes = {
        "`<a-s>` for character jump, `<a-S>` for treesitter jump.",
        "`<c-s>` toggles flash in search mode.",
        "Works in operator-pending mode: `d<a-s>`, `y<a-s>`.",
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
