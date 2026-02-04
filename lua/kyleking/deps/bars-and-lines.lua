local MiniDeps = require("mini.deps")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Load mini.icons early so other plugins can detect and use it
now(function()
    require("mini.icons").setup({
        -- Use default icon set (requires Nerd Fonts)
        style = "glyph", -- Use actual icons, not ASCII
        -- Customize specific icons if needed
        -- extension = { lua = { glyph = "󰢱", hl = "MiniIconsAzure" } },
    })
end)

later(function()
    add("RRethy/vim-illuminate")
    require("illuminate").configure({
        delay = 200,
        min_count_to_highlight = 2,
        large_file_overrides = { providers = { "lsp" } },
        -- Disable in terminal buffers for performance
        modes_denylist = { "t" }, -- Terminal mode
        should_enable = function(bufnr)
            -- Skip terminal buffers
            return vim.bo[bufnr].buftype ~= "terminal"
        end,
    })

    local K = vim.keymap.set
    K("n", "]r", function() require("illuminate")["goto_next_reference"](false) end, { desc = "Next reference" })
    K("n", "[r", function() require("illuminate")["goto_prev_reference"](false) end, { desc = "Previous reference" })
    K("n", "<leader>ur", function() require("illuminate").toggle() end, { desc = "Toggle reference highlighting" })
    K(
        "n",
        "<leader>uR",
        function() require("illuminate").toggle_buf() end,
        { desc = "Toggle reference highlighting (buffer)" }
    )
end)

-- Load statusline (extracted to separate module)
require("kyleking.deps.statusline")

later(function()
    local MiniTabline = require("mini.tabline")

    MiniTabline.setup({
        show_icons = true,
        set_vim_settings = true,
        tabpage_section = "right",
    })

    -- Apply nightfly-inspired theme colors
    local colors = require("kyleking.theme").get_colors()

    -- Tabline colors matching statusline theme
    vim.api.nvim_set_hl(0, "MiniTablineCurrent", { fg = colors.fg1, bg = colors.bg2, bold = true })
    vim.api.nvim_set_hl(0, "MiniTablineVisible", { fg = colors.fg2, bg = colors.bg1 })
    vim.api.nvim_set_hl(0, "MiniTablineHidden", { fg = colors.fg3, bg = colors.bg0 })
    vim.api.nvim_set_hl(0, "MiniTablineModifiedCurrent", { fg = colors.orange, bg = colors.bg2, bold = true })
    vim.api.nvim_set_hl(0, "MiniTablineModifiedVisible", { fg = colors.orange, bg = colors.bg1 })
    vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden", { fg = colors.orange, bg = colors.bg0 })
    vim.api.nvim_set_hl(0, "MiniTablineFill", { bg = colors.bg0 })
    vim.api.nvim_set_hl(0, "MiniTablineTabpagesection", { fg = colors.fg1, bg = colors.bg2, bold = true })
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
