return {
    title = "Highlight Patterns (mini.hipatterns)",
    see_also = { "MiniHipatterns" },
    desc = "Highlight keywords and patterns in buffers.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Keywords: FIXME, TODO, NOTE, PLANNED, WARNING, HACK, PERF, TEST, FYI.",
        "Custom PLANNED keyword uses `#FCD7AD` background.",
        "`<leader>ft` opens picker to find all highlighted patterns in buffer.",
    },

    grammars = {
        {
            pattern = "<leader>ft",
            desc = "Find TODO patterns",
            tests = {
                {
                    name = "find TODO keyword",
                    setup = {
                        fn = function()
                            -- Hipatterns applies highlights asynchronously
                            vim.cmd("doautocmd BufEnter")
                            vim.wait(50)
                        end,
                    },
                    before = { "-- TODO: fix this", "-- NOTE: important" },
                    expect = {
                        snapshot = true,
                    },
                },
            },
        },
        {
            pattern = "auto-highlight",
            desc = "Automatic keyword highlighting",
            tests = {
                {
                    name = "FIXME highlighted",
                    setup = {
                        fn = function()
                            vim.cmd("doautocmd BufEnter")
                            vim.wait(50)
                        end,
                    },
                    before = { "-- FIXME: broken" },
                    expect = { snapshot = true },
                },
                {
                    name = "PLANNED highlighted",
                    setup = {
                        fn = function()
                            vim.cmd("doautocmd BufEnter")
                            vim.wait(50)
                        end,
                    },
                    before = { "-- PLANNED: feature" },
                    expect = { snapshot = true },
                },
            },
        },
    },
}
