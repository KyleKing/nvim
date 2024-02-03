return {
    "kevinhwang91/nvim-hlslens",
    opts = {
        calm_down = true,
    },
    keys = {
        -- FYI: debug mapping with `:map ...`
        {
            "n",
            [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
            noremap = true,
            silent = true,
            desc = "Next Match",
        },
        {
            "N",
            [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
            noremap = true,
            silent = true,
            desc = "Previous Match",
        },

        -- TODO: Respect smartcase with:
        --  https://github.com/olimorris/dotfiles-1/blob/0a3168e068e21fd9f51be27fe7bdb72ef2643d88/.config/nvim/lua/plugins/hlslens.lua#L11-L31
        { "*", [[*<Cmd>lua require('hlslens').start()<CR>]], noremap = true, silent = true, desc = "Match Word" },
        { "#", [[#<Cmd>lua require('hlslens').start()<CR>]], noremap = true, silent = true, desc = "Match Word" },
        { "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], noremap = true, silent = true, desc = "Match Word" },
        { "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], noremap = true, silent = true, desc = "Match Word" },
    },
}
