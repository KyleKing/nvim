return {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm", "TermExec" },
    opts = {
        shading_factor = 4,
        direction = "float",
    },
    keys = {
        {
            "<leader>gg",
            function()
                local astro = require("astro.utils")
                local worktree = astro.file_worktree()
                local flags = worktree and (" --work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir)
                    or ""
                astro.toggle_term_cmd("lazygit " .. flags)
            end,
            desc = "ToggleTerm lazygit",
        },
        {
            -- https://github.com/ClementTsang/bottom
            "<leader>tb",
            function()
                local astro = require("astro.utils")
                astro.toggle_term_cmd("btm")
            end,
            desc = "ToggleTerm 'bottom' Processes",
        },
        {
            "<leader>tp",
            function()
                local astro = require("astro.utils")
                astro.toggle_term_cmd("python")
            end,
            desc = "ToggleTerm python",
        },
        { "<leader>tf", "<Cmd>ToggleTerm direction=float<CR>", desc = "ToggleTerm float" },
        { "<leader>th", "<Cmd>ToggleTerm size=15 direction=horizontal<CR>", desc = "ToggleTerm horizontal split" },
        { "<leader>tv", "<Cmd>ToggleTerm size=80 direction=vertical<CR>", desc = "ToggleTerm vertical split" },
        { "<C-'>", "<Cmd>ToggleTerm<CR>", desc = "Toggle terminal", mode = { "n", "t" } },
    },
}
