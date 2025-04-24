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
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("EdenEast/nightfox.nvim")
    require("nightfox").setup({
        dim_inactive = true, -- Non focused panes set to alternative background
    })

    vim.cmd("syntax enable")
    vim.cmd.colorscheme("nightfox")

    -- Override line number styles with colors from https://www.nordtheme.com
    --  Alternatively, override the theme directly: https://stackoverflow.com/a/76039670/3219667
    vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#98bbba", bold = true })
    -- vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#94bfce", bold = true })
    vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#87a0be", bold = true })
end)
