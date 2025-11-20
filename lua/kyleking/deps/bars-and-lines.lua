local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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

later(function()
    add({
        source = "nvim-lualine/lualine.nvim",

        depends = {
            "nvim-tree/nvim-web-devicons",
        },
    })

    local rel_filename = {
        "filename",
        file_status = true,
        new_file_status = true,
        path = 1, -- 0: Filename, 1: Relative path, 2: Absolute path
        shorting_target = 40, -- Shortens path to leave 'n' spaces in the window
    }

    -- Custom component for workspace root
    local workspace_root = {
        function()
            if vim.fn.exists("*kyleking_workspace_root") == 1 then
                return _G.kyleking_workspace_root()
            end
            return ""
        end,
        cond = function()
            if vim.fn.exists("*kyleking_workspace_root") == 1 then
                return _G.kyleking_workspace_root() ~= ""
            end
            return false
        end,
    }

    require("lualine").setup({
        options = {
            -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
            theme = "nightfly",
        },
        sections = {
            lualine_b = { "branch", "diff", "diagnostics", workspace_root },
            lualine_c = { rel_filename },
            lualine_x = { {} }, -- Remove filetype, etc.
            -- FYI: example displaying status of spell: https://github.com/nvim-lualine/lualine.nvim/issues/487#issuecomment-1345625242
        },
        extensions = {
            "fugitive",
            "man",
            "quickfix",
            "toggleterm",
            "trouble",
        },
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
