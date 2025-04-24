local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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
    -- Adapted from: https://github.com/hrsh7th/nvim-cmp?tab=readme-ov-file#recommended-configuration
    cmp.setup({
        -- Default snippet completion
        snippet = {
            expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        -- Configure snippet sources
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "lazydev" },
            { name = "treesitter" },
            { name = "nvim_lua" },
            { name = "luasnip" }, -- Snippets
            { name = "nvim_lsp_signature_help" },
        }, {
            -- Reduce false positives by placing these in the secondary completions category
            { name = "async_path" },
            { name = "buffer", keyword_length = 3 },
        }),
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
    cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = "buffer" },
        },
    })
    cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = "cmdline" },
        }, {
            { name = "async_path" },
        }),
    })
end

later(function()
    add({
        source = "hrsh7th/nvim-cmp",
        dependencies = {
            "VonHeikemen/lsp-zero.nvim", -- Configured in plugins.lsp.lsp-zero
            -- Sources
            "hrsh7th/cmp-nvim-lsp", -- Source: nvim_lsp
            "hrsh7th/cmp-buffer", -- Source: buffer
            "hrsh7th/cmp-nvim-lsp-signature-help", -- Source: nvim_lsp_signature_help
            "ray-x/cmp-treesitter", -- Source: treesitter
            "hrsh7th/cmp-cmdline", -- Source: cmdline
            "hrsh7th/cmp-nvim-lua", -- Source nvim_lua
            "folke/lazydev.nvim", -- Source lazydev. Replaces folke/neodev.nvim
            -- Two options for path completions:
            -- "hrsh7th/cmp-path", -- Source: path
            "https://codeberg.org/FelipeLema/cmp-async-path", -- Source: async_path

            -- PLANNED: migrate to mini.deps or replace
            -- {
            --     "L3MON4D3/LuaSnip", -- There is an alternative 'ultisnips'
            --     build = "make install_jsregexp", -- install jsregexp (optional!).
            --     dependencies = {
            --         { "rafamadriz/friendly-snippets" }, -- Loaded automatically
            --         { "saadparwaiz1/cmp_luasnip" }, -- Source: luasnip
            --     },
            -- },
        },
    })

    config_cmp()
end)
