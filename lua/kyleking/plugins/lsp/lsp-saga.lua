-- Improves the LSP UI. Docs: https://nvimdev.github.io/lspsaga
-- Includes features like outline, replace in project, preview of code actions, etc.
-- NOTE: example configuration: https://github.com/niksingh710/nvim/blob/907b2b5d6d0027f67972912ec4d96777aa8d797b/lua/plugins/lsp/init.lua
return {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
        require("lspsaga").setup({
            outline = {
                layout = "float",
            },
            lightbulb = { enable = false },
            symbol_in_winbar = { enable = false },
            symbols_in_winbar = { enable = false },
            -- beacon = { enable = false },
        })
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter", -- optional
        "nvim-tree/nvim-web-devicons", -- optional
    },
    keys = {
        -- TODO: Add keymaps: https://github.com/glepnir/nvim/blob/fb836831253f83f3ec647691ae8e3e63934407a2/lua/keymap/init.lua
        --  or: https://github.com/AGou-ops/dotfiles/blob/d1bc9e7a354d9cf434151aff8876c867bb22de02/neovim/lua/plugins/lspsaga.lua#L5-L60
    },
}
