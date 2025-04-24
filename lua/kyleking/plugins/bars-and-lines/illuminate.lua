---@class LazyPluginSpec
return {
    "RRethy/vim-illuminate",
    event = "BufRead",
    opts = {
        delay = 200,
        min_count_to_highlight = 2,
        large_file_overrides = { providers = { "lsp" } },
    },
    -- FYI: Required because naming is non-standard for lazy (e.g. no .setup())
    config = function(...) require("illuminate").configure(...) end,
    keys = {
        { "]r", function() require("illuminate")["goto_next_reference"](false) end, desc = "Next reference" },
        { "]r", function() require("illuminate")["goto_prev_reference"](false) end, desc = "Previous reference" },
        { "<leader>ur", function() require("illuminate").toggle() end, desc = "Toggle reference highlighting" },
        {
            "<leader>uR",
            function() require("illuminate").toggle_buf() end,
            desc = "Toggle reference highlighting (buffer)",
        },
    },
}
