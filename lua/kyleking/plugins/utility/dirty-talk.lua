-- Extend vim spelling dictionary with dynamically generated one
return {
    "psliwka/vim-dirtytalk",
    build = ":DirtytalkUpdate",
    lazy = true,
    config = function() vim.opt.spelllang = { "en_us", "programming" } end,
    keys = {
        {
            "<leader>pzs",
            "<Cmd>!sort -u ${HOME}/.config/nvim/spell/en.utf-8.add -o ${HOME}/.config/nvim/spell/en.utf-8.add<CR>",
            desc = "Shell Sort English Spelllang",
        },
    },
}
