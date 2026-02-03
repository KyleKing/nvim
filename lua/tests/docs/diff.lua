return {
    title = "Git Diff (mini.diff)",
    see_also = { "MiniDiff" },
    desc = "Show git diff overlay in buffers.",
    source = "lua/kyleking/deps/git.lua",

    notes = {
        "Toggle diff overlay with `<leader>ugd`.",
        "Shows added (green), deleted (red), and modified (yellow) lines.",
        "Works with modified files in git repositories.",
    },

    grammars = {
        {
            pattern = "<leader>ugd",
            desc = "Toggle diff overlay",
            tests = {
                {
                    name = "config check",
                    expect = {
                        fn = function(_ctx)
                            local MiniDiff = require("mini.diff")
                            local MiniTest = require("mini.test")
                            MiniTest.expect.equality(type(MiniDiff.toggle_overlay), "function")
                            MiniTest.expect.equality(MiniDiff.config.view.style, "sign")
                        end,
                    },
                },
            },
        },
    },
}
