return {
    title = "Surround (mini.surround)",
    see_also = { "MiniSurround" },
    desc = "Add, delete, find, and replace surrounding pairs.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Custom: `f` for function calls -- `saiwf` prompts for function name and wraps with `func(...)`.",
        "`s` is disabled in normal/visual mode to avoid conflict. Use `cl` instead.",
    },

    grammars = {
        {
            pattern = "sa{motion}{char}",
            desc = "Add surrounding",
            tests = {
                {
                    name = "word with quotes",
                    keys = 'saiw"',
                    before = { "word" },
                    expect = { lines = { '"word"' } },
                },
                {
                    name = "word with parens",
                    keys = "saiw)",
                    before = { "word" },
                    expect = { lines = { "(word)" } },
                },
                {
                    name = "WORD with braces",
                    keys = "saW}",
                    before = { "foo.bar" },
                    expect = { lines = { "{foo.bar}" } },
                },
                {
                    name = "to end of line",
                    keys = "sa$)",
                    before = { "hello world" },
                    cursor = { 1, 6 },
                    expect = { lines = { "hello (world)" } },
                },
            },
        },
        {
            pattern = "sd{char}",
            desc = "Delete surrounding",
            tests = {
                {
                    name = "delete quotes",
                    keys = 'sd"',
                    before = { '"word"' },
                    cursor = { 1, 2 },
                    expect = { lines = { "word" } },
                },
                {
                    name = "delete parens",
                    keys = "sd)",
                    before = { "(nested)" },
                    cursor = { 1, 3 },
                    expect = { lines = { "nested" } },
                },
            },
        },
        {
            pattern = "sr{old}{new}",
            desc = "Replace surrounding",
            tests = {
                {
                    name = "quotes to single quotes",
                    keys = [[sr"']],
                    before = { '"word"' },
                    cursor = { 1, 2 },
                    expect = { lines = { "'word'" } },
                },
                {
                    name = "parens to brackets",
                    keys = "sr)>",
                    before = { "(inner)" },
                    cursor = { 1, 3 },
                    expect = { lines = { "<inner>" } },
                },
            },
        },
        {
            pattern = "sf / sF",
            desc = "Find surrounding (right / left)",
            tests = {
                {
                    name = "find right paren",
                    keys = "sf)",
                    before = { "a (b) c" },
                    cursor = { 1, 3 },
                    expect = { cursor = { 1, 4 } },
                },
            },
        },
        {
            pattern = "sh",
            desc = "Highlight surrounding",
            tests = {
                {
                    name = "highlight parens",
                    keys = "sh)",
                    before = { "(word)" },
                    cursor = { 1, 2 },
                    expect = { snapshot = true },
                },
            },
        },
    },
}
