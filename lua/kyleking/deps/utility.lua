local MiniDeps = require("mini.deps")
local deps_utils = require("kyleking.deps_utils")
local add, later = MiniDeps.add, deps_utils.maybe_later

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
    local K = vim.keymap.set
    K(
        "n",
        -- From: https://github.com/nickjj/dotfiles/blob/d3c2b74f50e786edf78eceaa5359145f6f370eb3/.config/zsh/.aliases#L47C12-L47C86
        "<leader>pzs",
        "<Cmd>!sort -u ${HOME}/.config/nvim/spell/en.utf-8.add --output=${HOME}/.config/nvim/spell/en.utf-8.add --unique --ignore-case<CR>",
        { desc = "Shell Sort English Spelllang" }
    )
end)

later(function()
    add({
        source = "https://gitlab.com/itaranto/preview.nvim.git",
        depends = { "aklt/plantuml-syntax" }, -- Required for plantuml filetype
    })
    -- Adapted from: https://github.com/ariefra/ar.nvim/blob/1444607e70a6639c68271e38603008f06859c5ae/lua/base/preview.lua
    -- and: https://github.com/cristianrgreco/nvim/blob/252d8a7c5996444d7194240ed1e3d2e4df33a6e6/lua/plugins/preview.nvim.lua
    -- and: https://gitlab.com/itaranto/preview.nvim/-/issues/4#note_2203787288

    -- Optional preview.nvim integration with graceful degradation
    local preview_ok, preview = pcall(require, "preview")
    if preview_ok then
        preview.setup({
            previewers_by_ft = {
                plantuml = {
                    name = "plantuml_png",
                    renderer = { type = "command", opts = { cmd = { "open", "-a", "Preview" } } },
                },
            },
            previewers = {
                plantuml_png = {
                    args = { "-pipe", "-tpng" },
                },
            },
            render_on_write = true,
        })
    end
end)

later(function()
    add({
        source = "KyleKing/patch_it.nvim",
    })
    local patch_it = require("patch_it")
    local K = vim.keymap.set

    -- Apply LLM-generated patches with fuzzy matching
    K("n", "<leader>paa", function()
        local target = vim.fn.input("Target file: ", "", "file")
        if target ~= "" then patch_it.apply_buffer(target) end
    end, { desc = "Apply patch from buffer" })

    K("n", "<leader>pap", function()
        local target = vim.fn.input("Target file: ", "", "file")
        if target ~= "" then patch_it.apply_buffer(target, { preview = true }) end
    end, { desc = "Preview patch from buffer" })

    K("n", "<leader>pab", function()
        -- Apply to file matching current buffer name (common LLM workflow)
        local current = vim.fn.expand("%:t")
        local target = vim.fn.input("Target file: ", current, "file")
        if target ~= "" then patch_it.apply_buffer(target) end
    end, { desc = "Apply patch (auto-suggest target)" })
end)

later(function() add("micarmst/vim-spellsync") end)

later(function()
    add("sontungexpt/url-open")
    require("url-open").setup({})
    local K = vim.keymap.set
    K("n", "<leader>uu", "<esc>:URLOpenUnderCursor<cr>", { desc = "Open URL" })
end)
