return {
    title = "Markdown/Djot Editing",
    see_also = { "markdown", "djot" },
    desc = "Custom utilities for markdown and djot: list editing and browser preview.",
    source = "lua/kyleking/utils/list_editing.lua, lua/kyleking/utils/preview.lua",

    notes = {
        "**List editing** (buffer-local for markdown/djot files):",
        "",
        "**Smart Enter** - `<CR>` in insert mode:",
        "- On non-empty list item: Creates new list item with same marker",
        "- On empty list item: Exits list (removes marker, stays on line)",
        "- Outside list: Normal `<CR>` behavior",
        "",
        "**List indentation** - `<Tab>` in insert mode:",
        "- Indents current list item by one level",
        "- Updates marker if needed (e.g., `-` becomes `  -`)",
        "",
        "**Supported list formats**:",
        "- Unordered: `- item`, `* item`, `+ item`",
        "- Ordered: `1. item`, `2) item`",
        "",
        "**Djot-specific behavior**:",
        "Automatically adds blank lines between nested lists to maintain proper djot syntax.",
        "",
        "---",
        "",
        "**Browser preview** (buffer-local for markdown/djot files):",
        "",
        "`<leader>cp` - Preview current file in browser",
        "`:Preview` - Command form",
        "",
        "**Markdown conversion** (tries in order):",
        "1. pandoc (if available)",
        "2. Python markdown module",
        "",
        "**Djot conversion**:",
        "Requires djot CLI: `npm install -g @djot/djot`",
        "",
        "**Behavior**:",
        "- Converts file to HTML",
        "- Writes to temp file with CSS styling",
        "- Opens in default browser",
        "- Temp file persists until system cleanup",
        "",
        "**Use case**:",
        "Quick visual check of markdown/djot rendering without external tools or build processes.",
    },

    grammars = {
        {
            pattern = "<CR> (insert mode)",
            desc = "Smart list continuation",
            tests = {
                {
                    name = "list editing setup",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, list_editing = pcall(require, "kyleking.utils.list_editing")
                            MiniTest.expect.equality(ok, true, "list_editing should be available")
                            if ok then
                                MiniTest.expect.equality(type(list_editing.handle_return), "function")
                                MiniTest.expect.equality(type(list_editing.handle_tab), "function")
                                MiniTest.expect.equality(type(list_editing.setup), "function")
                            end
                        end,
                    },
                },
            },
        },
        {
            pattern = "<leader>cp",
            desc = "Preview in browser",
            tests = {
                {
                    name = "preview setup",
                    expect = {
                        fn = function(_ctx)
                            local MiniTest = require("mini.test")
                            local ok, preview = pcall(require, "kyleking.utils.preview")
                            MiniTest.expect.equality(ok, true, "preview should be available")
                            if ok then
                                MiniTest.expect.equality(type(preview.preview), "function")
                                MiniTest.expect.equality(type(preview.setup), "function")
                            end
                        end,
                    },
                },
            },
        },
    },
}
