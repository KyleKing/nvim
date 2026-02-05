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
    -- Use native tabline to show only tabs (no buffer list)
    -- Buffers accessible via mini.pick (<leader>fb) or :ls
    vim.opt.showtabline = 1 -- Show tabline only when multiple tabs exist

    -- Apply nightfly-inspired theme colors for native tabline
    local colors = require("kyleking.theme").get_colors()

    vim.api.nvim_set_hl(0, "TabLine", { fg = colors.fg3, bg = colors.bg0 })
    vim.api.nvim_set_hl(0, "TabLineSel", { fg = colors.fg1, bg = colors.bg2, bold = true })
    vim.api.nvim_set_hl(0, "TabLineFill", { bg = colors.bg0 })
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
