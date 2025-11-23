local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Extend vim spelling dictionary with dynamically generated one
---@class LazyPluginSpec
later(function()
    add({
        source = "psliwka/vim-dirtytalk",
        hooks = {
            post_checkout = function() vim.cmd("DirtytalkUpdate") end,
            post_install = function() vim.cmd("DirtytalkUpdate") end,
        },
    })
    vim.opt.spelllang = { "en_us", "programming" }
    vim.keymap.set(
        "n",
        -- From: https://github.com/nickjj/dotfiles/blob/d3c2b74f50e786edf78eceaa5359145f6f370eb3/.config/zsh/.aliases#L47C12-L47C86
        "<leader>pzs",
        "<Cmd>!sort -u ${HOME}/.config/nvim/spell/en.utf-8.add --output=${HOME}/.config/nvim/spell/en.utf-8.add --unique --ignore-case<CR>",
        { desc = "Shell Sort English Spelllang" }
    )
end)

-- gx.nvim - Enhanced URL/file opening (replaces both url-open and enhances built-in gx)
later(function()
    add({
        source = "chrishrb/gx.nvim",
        depends = { "nvim-lua/plenary.nvim" },
    })
    require("gx").setup({
        open_browser_args = {}, -- specify any arguments, such as --background for macOS' "open".
        handler_options = {
            search_engine = "ecosia", -- you can select between google, bing, duckduckgo, and ecosia
        },
    })
    vim.g.netrw_nogx = 1 -- disable netrw gx
    vim.keymap.set({ "n", "x" }, "gx", "<cmd>Browse<cr>", { desc = "Open URL/file under cursor" })
    vim.keymap.set("n", "<leader>uu", "<cmd>Browse<cr>", { desc = "Open URL/file under cursor" })
end)

later(function()
    add({
        source = "https://gitlab.com/itaranto/preview.nvim",
        depends = { "aklt/plantuml-syntax" }, -- Required for plantuml filetype
    })
    -- Adapted from: https://github.com/ariefra/ar.nvim/blob/1444607e70a6639c68271e38603008f06859c5ae/lua/base/preview.lua
    -- and: https://github.com/cristianrgreco/nvim/blob/252d8a7c5996444d7194240ed1e3d2e4df33a6e6/lua/plugins/preview.nvim.lua
    -- and: https://gitlab.com/itaranto/preview.nvim/-/issues/4#note_2203787288
    -- FIXME: preview not found on new laptop
    -- require("preview").setup({
    --     previewers_by_ft = {
    --         plantuml = {
    --             name = "plantuml_png",
    --             renderer = { type = "command", opts = { cmd = { "open", "-a", "Preview" } } },
    --             -- renderer = { type = "command", opts = { cmd = { "open" } } },
    --         },
    --     },
    --     previewers = {
    --         plantuml_png = {
    --             args = { "-pipe", "-tpng" },
    --         },
    --     },
    --     render_on_write = true,
    -- })
end)

later(function() add("micarmst/vim-spellsync") end)
