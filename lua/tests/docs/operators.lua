return {
    title = "Operators (mini.operators)",
    see_also = { "MiniOperators" },
    desc = "Additional text operators: sort, evaluate, multiply, replace, exchange.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Sort (`gs`) works with various delimiters (comma, semicolon, space).",
        "Evaluate (`g=`) works with Lua expressions: `2+3` becomes `5`.",
        "Multiply (`gm`) duplicates text: `3gmiw` duplicates word 3 times.",
        "Replace (`gr`) disabled by default (empty prefix).",
        "Exchange (`gx`) disabled by default (empty prefix).",
    },

    grammars = {
        {
            pattern = "gs{motion}",
            desc = "Sort with motion",
            tests = {
                {
                    name = "sort comma-separated",
                    keys = "gsi)",
                    before = { "(c, a, b)" },
                    cursor = { 1, 1 },
                    expect = { lines = { "(a, b, c)" } },
                },
                {
                    name = "sort lines in paragraph",
                    keys = "gsip",
                    before = { "zebra", "apple", "banana", "" },
                    cursor = { 1, 0 },
                    expect = { lines = { "apple", "banana", "zebra", "" } },
                },
            },
        },
        {
            pattern = "g={motion}",
            desc = "Evaluate Lua expression",
            tests = {
                {
                    name = "config check",
                    expect = {
                        fn = function(_ctx)
                            local MiniOperators = require("mini.operators")
                            local MiniTest = require("mini.test")

                            MiniTest.expect.equality(MiniOperators.config.evaluate.prefix, "g=")
                            MiniTest.expect.equality(MiniOperators.config.sort.prefix, "gs")
                            MiniTest.expect.equality(MiniOperators.config.multiply.prefix, "gm")
                        end,
                    },
                },
            },
        },
        {
            pattern = "gm{motion}",
            desc = "Multiply/duplicate text",
            tests = {
                {
                    name = "multiply word 3 times",
                    keys = "3gmiw",
                    before = { "word" },
                    cursor = { 1, 0 },
                    expect = { lines = { "wordwordword" } },
                },
            },
        },
    },
}
