-- Extend vim spelling dictionary with dynamically generated one
---@class LazyPluginSpec
return {
    "psliwka/vim-dirtytalk",
    build = ":DirtytalkUpdate",
    lazy = true,
    config = function() vim.opt.spelllang = { "en_us", "programming" } end,
    keys = {
        {
            -- From: https://github.com/nickjj/dotfiles/blob/d3c2b74f50e786edf78eceaa5359145f6f370eb3/.config/zsh/.aliases#L47C12-L47C86
            "<leader>pzs",
            "<Cmd>!sort -u ${HOME}/.config/nvim/spell/en.utf-8.add --output=${HOME}/.config/nvim/spell/en.utf-8.add --unique --ignore-case<CR>",
            desc = "Shell Sort English Spelllang",
        },
    },
}
