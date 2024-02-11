local function config_bash()
    local lspconfig = require("lspconfig")
    lspconfig.bashls.setup({})
end

local function config_lua()
    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    lspconfig.lua_ls.setup({
        format = { enable = false }, -- The builtin formatter is CppCXY/EmmyLuaCodeStyle (https://luals.github.io/wiki/formatter)
        capabilities = capabilities,
    })
end

local function config_pylsp(python_path)
    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    lspconfig.pylsp.setup({
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
        flags = {
            debounce_text_changes = 200,
        },
        capabilities = capabilities,
    })
end

local function config_pyright(python_path)
    local lspconfig = require("lspconfig")
    lspconfig.pyright.setup({
        settings = {
            python = {
                pythonPath = python_path,
            },
        },
    })
end

local function config_typescript()
    local lspconfig = require("lspconfig")
    lspconfig.tsserver.setup({})
end

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

local function config()
    -- See logs with `:LspInfo` and `:LspLog`
    -- vim.lsp.set_log_level("debug")

    local python_path = require("kyleking.utils.system_utils").get_python_path()

    customize_lsp_ui()

    local lsp_zero = require("lsp-zero")
    config_bash()
    config_lua() -- Requires 'brew install lua-language-server'
    config_pylsp(python_path) -- Requires 'pipx install python-lsp-server'
    config_pyright(python_path) -- Requires 'pipx install pyright'
    config_typescript()

    -- Full list of keymaps added from default:
    --   https://github.com/VonHeikemen/lsp-zero.nvim?tab=readme-ov-file#keybindings
    ---@diagnostic disable-next-line: unused-local
    lsp_zero.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp_zero.default_keymaps({ buffer = bufnr })
    end)

    -- require("mason").setup({})
    -- require("mason-lspconfig").setup({
    --     handlers = {
    --         lsp_zero.default_setup,
    --     },
    -- })

    local cmp = require("cmp")
    local cmp_action = require("lsp-zero").cmp_action()
    -- Configure snippets. Based on: https://lsp-zero.netlify.app/v3.x/autocomplete.html#add-an-external-collection-of-snippets
    local cmp_format = require("lsp-zero").cmp_format()
    require("luasnip.loaders.from_vscode").lazy_load()
    cmp.setup({
        -- Configure snippet sources
        sources = {
            { name = "buffer" },
            { name = "emoji" },
            { name = "luasnip" },
            { name = "nvim_lsp" },
            {
                name = "omni",
                option = { disable_omnifuncs = { "v:lua.vim.lsp.omnifunc" } },
            },
            { name = "path" },
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

-- local function config()
--     -- Global mappings.
--     -- See `:help vim.diagnostic.*` for documentation on any of the below functions
--     vim.keymap.set("n", "<leader>le", vim.diagnostic.open_float, { desc = "Open Float" })
--     vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to Previous" })
--     vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to Next" })
--     vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Set Loc List" })
--
--     -- Use LspAttach autocommand to only map the following keys
--     -- after the language server attaches to the current buffer
--     vim.api.nvim_create_autocmd("LspAttach", {
--         group = vim.api.nvim_create_augroup("UserLspConfig", {}),
--         callback = function(ev)
--             -- Enable completion triggered by <c-x><c-o>
--             vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
--
--             local function map(mode, lhs, rhs, opts)
--                 opts = opts or {}
--                 opts.silent = true
--                 opts.buffer = ev.buf
--                 vim.keymap.set(mode, lhs, rhs, opts)
--             end
--
--             -- Buffer local mappings.
--             -- See `:help vim.lsp.*` for documentation on any of the below functions
--             map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
--             map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Defintion" })
--             map("n", "<leader>lK", vim.lsp.buf.hover, { desc = "Hover" })
--             map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
--             map("n", "<leader>lH", vim.lsp.buf.signature_help, { desc = "Signature Help" })
--             map("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add Folder" })
--             map("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Folder" })
--             map(
--                 "n",
--                 "<leader>lwl",
--                 function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
--                 { desc = "Show Folders" }
--             )
--             map("n", "<leader>lD", vim.lsp.buf.type_definition, { desc = "Type Definition" })
--             map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename" })
--             map({ "n", "v" }, "<leader>lc", vim.lsp.buf.code_action, { desc = "Code Action" })
--             map("n", "gr", vim.lsp.buf.references, { desc = "Buffer References" })
--             -- Uses 'server_capabilities.documentFormattingProvider'
--             map("n", "<leader>lF", function() vim.lsp.buf.format({ async = true }) end, { desc = "(Old) LSP Format" })
--         end,
--     })
-- end

return {
    "VonHeikemen/lsp-zero.nvim",
    event = "BufRead",
    dependencies = {
        -- PLANNED: Revisit auto-installation of LSP servers
        -- { "williamboman/mason.nvim" },
        -- { "williamboman/mason-lspconfig.nvim" },

        { "neovim/nvim-lspconfig" },
        { "hrsh7th/cmp-nvim-lsp" }, -- Source: nvim_lsp
        { "hrsh7th/nvim-cmp" },
        { "hrsh7th/cmp-buffer" }, -- Source: buffer
        { "hrsh7th/cmp-emoji" }, -- Source: emoji
        { "hrsh7th/cmp-omni" }, -- Source: omni
        { "hrsh7th/cmp-path" }, -- Source: path
        {
            "L3MON4D3/LuaSnip",
            build = "make install_jsregexp", -- install jsregexp (optional!).
            dependencies = {
                { "saadparwaiz1/cmp_luasnip" }, -- Source: luasnip
                { "rafamadriz/friendly-snippets" }, -- Loaded automatically
            },
        },
        { "j-hui/fidget.nvim", opts = {} }, -- Useful status updates for LSP
        { "folke/neodev.nvim", opts = {} }, -- Additional lua configuration
        { "onsails/lspkind.nvim" }, -- For symbols
        -- PLANNED: consider https://github.com/quangnguyen30192/cmp-nvim-ultisnips
    },
    init = function()
        -- Source: https://vi.stackexchange.com/a/39075/44707
        local border = "single"
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border })
        vim.lsp.handlers["textDocument/signatureHelp"] =
            vim.lsp.with(vim.lsp.handlers.signature_help, { border = border })
        vim.diagnostic.config({ float = { border = border } })
        require("lspconfig.ui.windows").default_options = { border = border }
    end,
    config = config,
}
