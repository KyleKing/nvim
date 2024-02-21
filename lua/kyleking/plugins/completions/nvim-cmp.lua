local function config_cmp()
    local cmp = require("cmp")
    local cmp_action = require("lsp-zero").cmp_action()
    local cmp_format = require("lspkind").cmp_format({
        mode = "symbol", -- show only symbol annotations
        maxwidth = 50, -- prevent the popup from showing more than provided characters
        ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead
        show_labelDetails = true, -- show labelDetails in menu. Disabled by default
    })
    require("luasnip.loaders.from_vscode").lazy_load()
    cmp.setup({
        -- Default snippet completion
        snippet = {
            expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        -- Configure snippet sources
        sources = cmp.config.sources({
            -- PLANNED: consider additional sources: https://github.com/hrsh7th/nvim-cmp/wiki/List-of-sources
            -- In particular: treesitter, etc.
            -- and revisit: https://github.com/hrsh7th/nvim-cmp?tab=readme-ov-file#recommended-configuration
            { name = "nvim_lsp" },
            { name = "nvim_lsp_signature_help" },
            { name = "nvim_lua" },
            -- {
            --     name = "omni",
            --     option = { disable_omnifuncs = { "v:lua.vim.lsp.omnifunc" } },
            -- },
            { name = "luasnip" },
            { name = "path" },
        }, {
            { name = "buffer", keyword_length = 3 }, -- Reduce false positives
        }),
        completion = {
            autocomplete = { "InsertEnter", "TextChanged" },
        },
        -- Customize mappings
        mapping = cmp.mapping.preset.insert({ -- Preset: ^n, ^p, ^y, ^e, you know the drill..
            -- Navigate completion options
            ["<C-j>"] = cmp.mapping.select_next_item(),
            ["<C-k>"] = cmp.mapping.select_prev_item(),
            -- Powerful tabbing (https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/autocomplete.md#enable-super-tab)
            --  If the completion menu is visible it will navigate to the next item in the list
            --  If the cursor is on top of a "snippet trigger" it'll expand it
            --  If the cursor can jump to a snippet placeholder, it moves to it
            --  If the cursor is in the middle of a word it displays the completion menu
            --  Else, it acts like a regular Tab key.
            ["<Tab>"] = cmp_action.luasnip_supertab(),
            ["<S-Tab>"] = cmp_action.luasnip_shift_supertab(),
            -- `Ctrl-Enter` key to confirm completion. Set `select` to `false` to only confirm explicitly selected items
            ["<C-CR>"] = cmp.mapping.confirm({ select = true }),
            -- Ctrl+Space to trigger completion menu
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<CR>"] = cmp.mapping.abort(),
            -- Scroll up and down in the completion documentation
            ["<C-u>"] = cmp.mapping.scroll_docs(-4),
            ["<C-d>"] = cmp.mapping.scroll_docs(4),
            -- Navigate between snippet placeholder
            ["<C-f>"] = cmp_action.luasnip_jump_forward(),
            ["<C-b>"] = cmp_action.luasnip_jump_backward(),
        }),
        -- Add borders to menu
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
        },
        --- (Optional) Show source name in completion menu
        formatting = {
            expandable_indicator = true,
            fields = { "abbr", "kind", "menu" },
            format = cmp_format,
        },
    })
    -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = "buffer" },
        },
    })
    -- PLANNED: revisit completions for commands
    -- -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
    -- cmp.setup.cmdline(":", {
    --     mapping = cmp.mapping.preset.cmdline(),
    --     sources = cmp.config.sources({
    --         { name = "path" },
    --     }, {
    --         { name = "cmdline" },
    --     }),
    -- })
end

return {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
        { "VonHeikemen/lsp-zero.nvim" }, -- Configured in plugins.lsp.lsp-zero
        { "hrsh7th/cmp-nvim-lsp" }, -- Source: nvim_lsp
        -- PLANNED: consider https://github.com/f3fora/cmp-spell
        { "hrsh7th/cmp-buffer" }, -- Source: buffer
        { "hrsh7th/cmp-nvim-lsp-signature-help" }, -- Source: nvim_lsp_signature_help
        { "hrsh7th/cmp-nvim-lua" }, -- Source nvim_lua
        -- { "hrsh7th/cmp-omni" }, -- PLANNED: Source: omni (and see both commented snippets above)
        { "hrsh7th/cmp-path" }, -- Source: path (PLANNED: use async_path instead from: https://github.com/FelipeLema/cmp-async-path)
        {
            "L3MON4D3/LuaSnip",
            build = "make install_jsregexp", -- install jsregexp (optional!).
            dependencies = {
                { "rafamadriz/friendly-snippets" }, -- Loaded automatically
                { "saadparwaiz1/cmp_luasnip" }, -- Source: luasnip
            },
        },
        -- PLANNED: consider https://github.com/quangnguyen30192/cmp-nvim-ultisnips
    },
    config = config_cmp,
}
