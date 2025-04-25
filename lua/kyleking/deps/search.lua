local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    add("kevinhwang91/nvim-hlslens")
    require("hlslens").setup({
        calm_down = true,
    })

    local K = vim.keymap.set
    -- FYI: debug mapping with `:map ...`
    K("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], {
        noremap = true,
        silent = true,
        desc = "Next Match",
    })
    K("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], {
        noremap = true,
        silent = true,
        desc = "Previous Match",
    })
    -- TODO: Respect smartcase with:
    --  https://github.com/olimorris/dotfiles-1/blob/0a3168e068e21fd9f51be27fe7bdb72ef2643d88/.config/nvim/lua/plugins/hlslens.lua#L11-L31
    K("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" })
    K("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" })
    K("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" })
    K("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], { noremap = true, silent = true, desc = "Match Word" })
end)
