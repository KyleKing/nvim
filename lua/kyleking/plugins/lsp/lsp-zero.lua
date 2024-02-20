local function customize_lsp_ui()
    -- PLANNED: this is redundant to the lsp-zero config
    local signs = {
        { name = "DiagnosticSignError", text = "", texthl = "DiagnosticSignError" },
        { name = "DiagnosticSignWarn", text = "", texthl = "DiagnosticSignWarn" },
        { name = "DiagnosticSignHint", text = "󰌵", texthl = "DiagnosticSignHint" },
        { name = "DiagnosticSignInfo", text = "󰋼", texthl = "DiagnosticSignInfo" },
    }
    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, sign)
    end

    -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
end

local function config_lsp()
    local lsp_zero = require("lsp-zero")

    -- Full list of keymaps added from default:
    --   https://github.com/VonHeikemen/lsp-zero.nvim?tab=readme-ov-file#keybindings
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    local K = vim.keymap.set
    -- Diagnostics are not exclusive to lsp servers, so they can be global
    -- -- These are set by lsp-zero automatically
    -- K("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to Previous" })
    -- K("n", "]d", vim.diagnostic.goto_next, { desc = "Go to Next" })
    K("n", "gl", vim.diagnostic.open_float, { desc = "Open LSP hover diagnostics" })
    K("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Open LSP diagnostics list" })

    -- Otherwise, limit mappings to attached buffer
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    ---@diagnostic disable-next-line: unused-local
    lsp_zero.on_attach(function(_client, bufnr)
        -- -- PLANNED: (Investigate) Enable completion triggered by <c-x><c-o> (note: lsp-zero has some logic for this internally that this may duplicate)
        -- vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

        -- FYI: I'm not using the default keybindings becayse they don't have desc for Which-Key
        --  and I prefer to namespace them in '<leader>l'
        --
        -- -- To learn the available actions see :help lsp-zero-keybindings
        -- lsp_zero.default_keymaps({ buffer = bufnr })

        local function map(mode, lhs, rhs, opts)
            opts = opts or {}
            opts.silent = true
            opts.buffer = bufnr
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
        map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Defintion" })
        map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
        map("n", "<leader>li", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
        map("n", "<leader>lo", vim.lsp.buf.type_definition, { desc = "Type Definition" })
        map("n", "<leader>lr", vim.lsp.buf.references, { desc = "Buffer References" })
        map("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "Signature Help" })
        map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename" })
        map(
            { "n", "v" },
            "<leader>la",
            function() vim.lsp.buf.code_action({ context = { only = { "quickfix", "refactor", "source" } } }) end,
            { desc = "Code Action" }
        )
        -- Uses 'server_capabilities.documentFormattingProvider'
        map(
            { "n", "x" },
            "<leader>lF",
            function() vim.lsp.buf.format({ async = true }) end,
            { desc = "(Old) LSP Format" }
        )
        -- -- Workspace
        -- -- PLANNED: consider using the LSP-Zero variants (LspZeroWorkspaceRemove, etc.)
        -- map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add Folder" })
        -- map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Folder" })
        -- map(
        --     "n",
        --     "<leader>lwl",
        --     function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
        --     { desc = "Show Folders" }
        -- )
    end)

    lsp_zero.set_sign_icons({ error = "", warn = "", hint = "󰌵", info = "󰋼" })
end

local function config_telescope()
    local K = vim.keymap.set
    local tele = require("telescope.builtin")
    K("n", "<leader>lzd", tele.lsp_definitions, { desc = "Telescope LSP Definintions" })
    K("n", "<leader>lzr", tele.lsp_references, { desc = "Telescope References" })
    K("n", "<leader>lzI", tele.lsp_implementations, { desc = "Telescope Implementations" })
    K("n", "<leader>lzD", tele.lsp_type_definitions, { desc = "Telescope Type Definition" })
    K("n", "<leader>lzs", tele.lsp_document_symbols, { desc = "Telescope Document Symbols" })
    K("n", "<leader>lzw", tele.lsp_dynamic_workspace_symbols, { desc = "Telescope Workspace Symbols" })
end

local function config_mason()
    local python_path = require("kyleking.utils.system_utils").get_python_path()
    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    require("mason").setup({})
    -- FIXME: support python!
    require("mason-lspconfig").setup({
        ensure_installed = {
            "bashls",
            -- "docker_compose_language_service",
            -- "dockerls",
            -- "jedi_language_server",
            "jsonls",
            "lua_ls",
            -- "marksman",
            -- "ruff_lsp",
            -- "tailwindcss",
            -- "taplo",
            "terraformls",
            "tsserver",
            "yamlls",
        },
        handlers = {
            require("lsp-zero").default_setup,
            lua_ls = function()
                require("lspconfig").lua_ls.setup({
                    capabilities = lsp_capabilities,
                    format = { enable = false }, -- The builtin formatter is CppCXY/EmmyLuaCodeStyle (https://luals.github.io/wiki/formatter)
                })
            end,
            jsonls = function()
                require("lspconfig").jsonls.setup({
                    capabilities = lsp_capabilities,
                    settings = {
                        json = {
                            schemas = require("schemastore").json.schemas(),
                            validate = { enable = true }, -- See: https://github.com/b0o/SchemaStore.nvim/issues/8
                        },
                    },
                })
            end,
            yamlls = function()
                require("lspconfig").yamlls.setup({
                    capabilities = lsp_capabilities,
                    settings = {
                        yaml = {
                            schemaStore = {
                                enable = false, -- You must disable built-in schemaStore support if you want to use schemastore and its advanced options like `ignore`.
                                url = "", -- Avoids a TypeError: Cannot read properties of undefined (reading 'length')
                            },
                            schemas = require("schemastore").yaml.schemas(),
                        },
                    },
                })
            end,
            pylsp = function()
                require("lspconfig").pylsp.setup({
                    capabilities = lsp_capabilities,
                    settings = {
                        pylsp = {
                            plugins = {
                                -- formatter options
                                black = { enabled = false },
                                autopep8 = { enabled = false },
                                yapf = { enabled = false },
                                -- linter options
                                pylint = { enabled = false, executable = "pylint" },
                                ruff = { enabled = false },
                                pyflakes = { enabled = false },
                                pycodestyle = { enabled = false },
                                -- type checker
                                pylsp_mypy = {
                                    enabled = true,
                                    overrides = { "--python-executable", python_path, true },
                                    report_progress = true,
                                    live_mode = false,
                                },
                                -- auto-completion options
                                jedi_completion = { fuzzy = false },
                                -- import sorting
                                isort = { enabled = false },
                            },
                        },
                    },
                    flags = { debounce_text_changes = 200 },
                })
            end,
            pyright = function()
                require("lspconfig").pyright.setup({
                    capabilities = lsp_capabilities,
                    settings = { python = { pythonPath = python_path } },
                })
            end,
        },
    })
end

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

-- Based on: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html
return {
    "VonHeikemen/lsp-zero.nvim",
    event = { "BufRead", "InsertEnter", "CmdlineEnter" },
    dependencies = {
        { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" } },
        { "hrsh7th/nvim-cmp" },
        { "neovim/nvim-lspconfig" },
        { "hrsh7th/cmp-nvim-lsp" }, -- Source: nvim_lsp
        {
            "L3MON4D3/LuaSnip",
            build = "make install_jsregexp", -- install jsregexp (optional!).
            dependencies = {
                -- PLANNED: consider https://github.com/f3fora/cmp-spell
                { "hrsh7th/cmp-buffer" }, -- Source: buffer
                { "hrsh7th/cmp-nvim-lsp-signature-help" }, -- Source: nvim_lsp_signature_help
                { "hrsh7th/cmp-nvim-lua" }, -- Source nvim_lua
                -- { "hrsh7th/cmp-omni" }, -- PLANNED: Source: omni (and see both commented snippets above)
                { "hrsh7th/cmp-path" }, -- Source: path (PLANNED: use async_path instead from: https://github.com/FelipeLema/cmp-async-path)
                { "rafamadriz/friendly-snippets" }, -- Loaded automatically
                { "saadparwaiz1/cmp_luasnip" }, -- Source: luasnip
            },
        },
        { "b0o/schemastore.nvim" }, -- JSON and Yaml Schemas
        { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP
        { "folke/neodev.nvim", opts = {} }, -- Additional lua configuration
        { "onsails/lspkind.nvim" }, -- For symbols
        { "nvim-telescope/telescope.nvim" },
        -- PLANNED: consider https://github.com/quangnguyen30192/cmp-nvim-ultisnips
    },
    config = function()
        -- FIXME: Split these back up into separate files
        -- See logs with `:LspInfo` and `:LspLog`
        -- vim.lsp.set_log_level("debug")
        customize_lsp_ui()
        config_lsp()
        config_telescope()
        config_mason()
        config_cmp()
    end,
}
