local MiniDeps = require("mini.deps")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Enable mini.icons early for icon support across plugins
now(function()
    require("mini.icons").setup()
    -- Set MiniIcons as the default provider for nvim-web-devicons compatibility
    MiniIcons = require("mini.icons")
end)

later(function()
    add("RRethy/vim-illuminate")
    require("illuminate").configure({
        delay = 200,
        min_count_to_highlight = 2,
        large_file_overrides = { providers = { "lsp" } },
    })

    local K = vim.keymap.set
    K("n", "]r", function() require("illuminate")["goto_next_reference"](false) end, { desc = "Next reference" })
    K("n", "]r", function() require("illuminate")["goto_prev_reference"](false) end, { desc = "Previous reference" })
    K("n", "<leader>ur", require("illuminate").toggle, { desc = "Toggle reference highlighting" })
    K("n", "<leader>uR", require("illuminate").toggle_buf, { desc = "Toggle reference highlighting (buffer)" })
end)

-- Use mini.statusline instead of lualine for simpler, lighter statusline
later(function()
    local statusline = require("mini.statusline")
    statusline.setup({
        content = {
            active = function()
                local mode, mode_hl = statusline.section_mode({ trunc_width = 999 })
                local git = statusline.section_git({ trunc_width = 40 })
                local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
                local filename = statusline.section_filename({ trunc_width = 140 })
                local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
                local location = statusline.section_location({ trunc_width = 75 })
                local search = statusline.section_searchcount({ trunc_width = 75 })

                -- Include lint progress if available
                local lint_info = vim.fn.exists('*kyleking_lint_progress') == 1
                    and _G.kyleking_lint_progress() or ''

                return statusline.combine_groups({
                    { hl = mode_hl, strings = { mode } },
                    { hl = "MiniStatuslineDevinfo", strings = { git, diagnostics, lint_info } },
                    "%<",
                    { hl = "MiniStatuslineFilename", strings = { filename } },
                    "%=",
                    { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
                    { hl = mode_hl, strings = { search, location } },
                })
            end,
        },
        use_icons = true,
        set_vim_settings = true,
    })
end)

later(function()
    add("fmbarina/multicolumn.nvim")

    require("multicolumn").setup({
        use_default_set = true,
        sets = {
            lua = {
                full_column = true,
                rulers = { 120 },
            },
            python = function()
                -- PLANNED: consider reading line length from pyproject.toml and caching result
                local rulers = function() return { 80, 120 } end
                return {
                    full_column = true,
                    rulers = rulers(),
                }
            end,
        },
    })
end)
