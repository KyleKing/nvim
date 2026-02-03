--[[
 Colorscheme Alternatives

- [catppuccin.lua](https://github.com/catppuccin/nvim)
- [melange-nvim](https://github.com/savq/melange-nvim) (and [Wezterm Config](https://github.com/savq/melange-nvim/blob/258e5afa978aa886e7ac346612e5f920a2b6be59/term/wezterm/melange_dark.toml))
- [sainnhe/everforest](https://github.com/sainnhe/everforest)
- "dracula/vim" (dracula)
- "folke/tokyonight.nvim" (tokyonight-storm)
- "joshdick/onedark.vim" (onedark)
- "rebelot/kanagawa.nvim" (kanagawa)
- "roflolilolmao/oceanic-next.nvim" (OceanicNext)
- "sickill/vim-monokai" (monokai)
- "sonph/onehalf" (onehalfdark)
- [RRethy/nvim-base16](https://github.com/RRethy/nvim-base16)
- [rose-pine](https://github.com/rose-pine/neovim)
]]

local MiniDeps = require("mini.deps")
local maybe_later = _G.maybe_later
local add, now, later = MiniDeps.add, MiniDeps.now, maybe_later

later(function()
    add("EdenEast/nightfox.nvim")
    require("nightfox").setup({
        dim_inactive = true, -- Non focused panes set to alternative background
    })

    vim.cmd("syntax enable")
    vim.cmd.colorscheme("nightfox")

    -- Override line number styles with nightfox palette colors
    --  Alternatively, override the theme directly: https://stackoverflow.com/a/76039670/3219667
    local theme = require("kyleking.theme")
    local colors = theme.get_colors()
    vim.api.nvim_set_hl(0, "LineNrAbove", { fg = colors.fg3, bold = true })
    vim.api.nvim_set_hl(0, "LineNrBelow", { fg = colors.fg2, bold = true })
end)
