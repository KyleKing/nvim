return {
    title = "Color & UI",
    see_also = {},
    desc = "Colorscheme: nightfox with custom highlights. `dim_inactive = true`.",
    source = "lua/kyleking/deps/colorscheme.lua, lua/kyleking/deps/color.lua, lua/kyleking/deps/bars-and-lines.lua",

    notes = {
        "**Color tools (ccc.nvim)**:",
        "`<leader>uc{C,c,p}` for color highlighting/conversion/picker",
        "",
        "**vim-illuminate**:",
        "`]r`/`[r` to jump between references of word under cursor",
        "",
        "**Highlighted keywords (mini.hipatterns)**:",
        "FIXME, HACK, TODO, NOTE, FYI, PLANNED, WARNING, PERF, TEST",
        "Use `<leader>ft` to search for TODO items",
        "",
        "**highlight-undo.nvim**:",
        "Undo/redo changes are briefly highlighted",
        "",
        "**Statusline (mini.statusline)**:",
        "Mode, git branch, diagnostics, dynamic filename, location. Disabled in temp sessions.",
        "",
        "**Column rulers (multicolumn.nvim)**:",
        "Lua 120, Python 80+120",
    },

    grammars = {
        {
            pattern = "<leader>uc",
            desc = "Color utilities",
            tests = {
                {
                    name = "color utilities available",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            -- Verify hipatterns is loaded
                            local MiniHipatterns = require("mini.hipatterns")
                            MiniTest.expect.equality(type(MiniHipatterns.setup), "function")
                        end,
                    },
                },
            },
        },
    },
}
