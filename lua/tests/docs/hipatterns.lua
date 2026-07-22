-- `doautocmd BufEnter` relies on mini.hipatterns' auto-enable autocmd, which skips
-- non-normal buftypes -- exactly what `helpers.create_test_buffer` produces (see
-- `runner.lua`'s `M.run_test`). Enabling directly bypasses that restriction (mini.hipatterns
-- supports manual enable() on any buffer) so these snapshots capture real highlight extmarks.
local function enable_and_wait()
    local hipatterns = require("mini.hipatterns")
    hipatterns.enable(0)
    vim.wait(300, function() return #hipatterns.get_matches(0) > 0 end, 20)
end

return {
    title = "Highlight Patterns (mini.hipatterns)",
    see_also = { "MiniHipatterns" },
    desc = "Highlight keywords and patterns in buffers.",
    source = "lua/kyleking/deps/editing-support.lua",

    notes = {
        "Keywords: FIXME, TODO, NOTE, PLANNED, WARNING, HACK, PERF, TEST, FYI.",
        "Custom PLANNED keyword uses `#FCD7AD` background.",
        "`<leader>ft` opens picker to find all highlighted patterns in buffer.",
        "Links: URLs (`@markup.link.url`), markdown link text (`@markup.link.label`), and `author/repo.nvim` plugin refs (`@markup.link`) are also highlighted -- see link_open.",
    },

    grammars = {
        {
            pattern = "<leader>ft",
            desc = "Find TODO patterns",
            tests = {
                {
                    name = "find TODO keyword",
                    setup = { fn = enable_and_wait },
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
                    setup = { fn = enable_and_wait },
                    before = { "-- FIXME: broken" },
                    expect = { snapshot = true },
                },
                {
                    name = "PLANNED highlighted",
                    setup = { fn = enable_and_wait },
                    before = { "-- PLANNED: feature" },
                    expect = { snapshot = true },
                },
            },
        },
        {
            pattern = "link highlighting",
            desc = "URL, markdown-link, and plugin-ref highlighting",
            tests = {
                {
                    name = "plain URL highlighted",
                    setup = { fn = enable_and_wait },
                    before = { "See https://example.com for details" },
                    expect = { snapshot = true },
                },
                {
                    name = "markdown link text highlighted",
                    setup = { fn = enable_and_wait },
                    before = { "[Neovim docs](https://neovim.io/doc)" },
                    expect = { snapshot = true },
                },
                {
                    name = "plugin ref highlighted",
                    setup = { fn = enable_and_wait },
                    before = { "Uses echasnovski/mini.nvim under the hood" },
                    expect = { snapshot = true },
                },
            },
        },
    },
}
