local function customize_lsp_ui()
    local icons = require("kyleking.utils.icons")
    local signs = {
        { name = "DiagnosticSignError", text = icons.get_icon("DiagnosticError"), texthl = "DiagnosticSignError" },
        { name = "DiagnosticSignWarn", text = icons.get_icon("DiagnosticWarn"), texthl = "DiagnosticSignWarn" },
        { name = "DiagnosticSignHint", text = icons.get_icon("DiagnosticHint"), texthl = "DiagnosticSignHint" },
        { name = "DiagnosticSignInfo", text = icons.get_icon("DiagnosticInfo"), texthl = "DiagnosticSignInfo" },
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
    K("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Set LSP Loc List" })
    -- -- These are set by lsp-zero automatically
    -- K("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to Previous" })
    -- K("n", "]d", vim.diagnostic.goto_next, { desc = "Go to Next" })
    K("n", "gl", vim.diagnostic.open_float, { desc = "Open LSP diagnostic float" })

    -- Otherwise, limit mappings to attached buffer
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    ---@diagnostic disable-next-line: unused-local
    lsp_zero.on_attach(function(client, bufnr)
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
        map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, { desc = "Code Action" })
        -- Uses 'server_capabilities.documentFormattingProvider'
        map(
            { "n", "x" },
            "<leader>lF",
            function() vim.lsp.buf.format({ async = true }) end,
            { desc = "(Old) LSP Format" }
        )
        -- Worwkspace
        map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add Folder" })
        map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Folder" })
        map(
            "n",
            "<leader>lwl",
            function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
            { desc = "Show Folders" }
        )
    end)
end

local function config_mason()
    local python_path = require("kyleking.utils.system_utils").get_python_path()
    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
    require("mason").setup({})
    require("mason-lspconfig").setup({
        ensure_installed = {
            "bashls",
            "lua_ls",
            "rust_analyzer",
            "tsserver",
        },
        handlers = {
            require("lsp-zero").default_setup,
            lua_ls = function()
                require("lspconfig").lua_ls.setup({
                    capabilities = lsp_capabilities,
                    format = { enable = false }, -- The builtin formatter is CppCXY/EmmyLuaCodeStyle (https://luals.github.io/wiki/formatter)
                })
            end,
            pylsp = function()
                require("lspconfig").pylsp.setup({
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
                    capabilities = lsp_capabilities,
                })
            end,
            pyright = function()
                require("lspconfig").pyright.setup({
                    settings = { python = { pythonPath = python_path } },
                    capabilities = lsp_capabilities,
                })
            end,
        },
    })
end

local function config_cmp()
    local cmp = require("cmp")
    local cmp_action = require("lsp-zero").cmp_action()
    local cmp_format = require("lsp-zero").cmp_format() -- Configure snippets. Based on: https://lsp-zero.netlify.app/v3.x/autocomplete.html#add-an-external-collection-of-snippets
    require("luasnip.loaders.from_vscode").lazy_load()
    cmp.setup({
        -- Configure snippet sources
        sources = {
            { name = "nvim_lsp" },
            { name = "luasnip" },
            -- {
            --     name = "omni",
            --     option = { disable_omnifuncs = { "v:lua.vim.lsp.omnifunc" } },
            -- },
            { name = "path" },
            { name = "buffer" }, -- Sometimes too many false positives
        },
        -- Pre-select the first item
        preselect = "item",
        completion = {
            autocomplete = { "InsertEnter", "TextChanged" },
            completeopt = "menu,menuone,noinsert",
        },
        -- Customize mappings
        mapping = cmp.mapping.preset.insert({
            ["<C-n>"] = cmp.mapping.select_next_item(),
            ["<C-p>"] = cmp.mapping.select_prev_item(),
            ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
            ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
            -- `Enter` key to confirm completion
            ["<CR>"] = cmp.mapping.confirm({
                select = true,
                behavior = cmp.ConfirmBehavior.Insert,
            }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            ["<S-CR>"] = cmp.mapping.confirm({
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
            }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            ["<C-CR>"] = function(fallback)
                cmp.abort()
                fallback()
            end,
            -- Ctrl+Space to trigger completion menu
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
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
        formatting = vim.tbl_deep_extend("force", cmp_format, {
            fields = { "abbr", "kind", "menu" },
            format = require("lspkind").cmp_format({
                mode = "symbol", -- show only symbol annotations
                maxwidth = 50, -- prevent the popup from showing more than provided characters
                ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead
                show_labelDetails = true, -- show labelDetails in menu. Disabled by default
            }),
        }),
    })
end

-- Based on: https://lsp-zero.netlify.app/v3.x/blog/you-might-not-need-lsp-zero.html
return {
    "VonHeikemen/lsp-zero.nvim",
    event = "BufRead",
    dependencies = {
        { "williamboman/mason-lspconfig.nvim", dependencies = { "williamboman/mason.nvim" } },
        { "hrsh7th/nvim-cmp" },
        { "neovim/nvim-lspconfig" },
        { "hrsh7th/cmp-nvim-lsp" }, -- Source: nvim_lsp
        {
            "L3MON4D3/LuaSnip",
            build = "make install_jsregexp", -- install jsregexp (optional!).
            dependencies = {
                { "hrsh7th/cmp-buffer" }, -- Source: buffer
                -- { "hrsh7th/cmp-omni" }, -- PLANNED: Source: omni (and see both commented snippets above)
                { "hrsh7th/cmp-path" }, -- Source: path
                { "saadparwaiz1/cmp_luasnip" }, -- Source: luasnip
                { "rafamadriz/friendly-snippets" }, -- Loaded automatically
            },
        },
        { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP
        { "folke/neodev.nvim", opts = {} }, -- Additional lua configuration
        { "onsails/lspkind.nvim" }, -- For symbols
        -- PLANNED: consider https://github.com/quangnguyen30192/cmp-nvim-ultisnips
    },
    -- PLANNED: how does this compare to the 'border' setting?
    -- init = function()
    --     -- Source: https://vi.stackexchange.com/a/39075/44707
    --     local border = "single"
    --     vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border })
    --     vim.lsp.handlers["textDocument/signatureHelp"] =
    --         vim.lsp.with(vim.lsp.handlers.signature_help, { border = border })
    --     vim.diagnostic.config({ float = { border = border } })
    --     require("lspconfig.ui.windows").default_options = { border = border }
    -- end,
    config = function()
        -- See logs with `:LspInfo` and `:LspLog`
        -- vim.lsp.set_log_level("debug")
        customize_lsp_ui()
        config_lsp()
        config_mason()
        config_cmp()
    end,
}

-- -- TODO: Finish merging the LSP config
--
-- -- -- Diagnostic keymaps
-- -- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
-- -- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
-- -- vim.keymap.set("n", "<leader>lm", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
-- -- vim.keymap.set("n", "<leader>ll", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
-- -- K("n", "<leader>ld", function() vim.diagnostic.open_float() end, { desc = "Hover diagnostics" })
-- -- K("n", "[d", function() vim.diagnostic.goto_prev() end, { desc = "Previous diagnostic" })
-- -- K("n", "]d", function() vim.diagnostic.goto_next() end, { desc = "Next diagnostic" })
-- -- K("n", "gl", function() vim.diagnostic.open_float() end, { desc = "Hover diagnostics" })
--
-- return function(_)
--     -- [[ Configure LSP ]]
--     --  This function gets run when an LSP connects to a particular buffer.
--     local on_attach = function(_, bufnr)
--         local nmap = function(keys, func, desc)
--             if desc then desc = "LSP: " .. desc end
--             vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
--         end
--
--         nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
--         nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
--
--         nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
--         nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
--         nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
--         nmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
--         nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
--         nmap("<leader>lws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
--
--         -- See `:help K` for why this keymap
--         nmap("K", vim.lsp.buf.hover, "Hover Documentation")
--         nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
--         nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
--
