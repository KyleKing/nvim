-- Minimal configuration from: https://github.com/neovim/nvim-lspconfig?tab=readme-ov-file#suggested-configuration
-- PLANNED: see project-local guidance: https://github.com/neovim/nvim-lspconfig/wiki/Project-local-settings

local function config_lua()
   local lspconfig = require("lspconfig")
   lspconfig.lua_ls.setup({
      on_init = function(client)
         local path = client.workspace_folders[1].name
         if not vim.loop.fs_stat(path .. "/.luarc.json") and not vim.loop.fs_stat(path .. "/.luarc.jsonc") then
            client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
               Lua = {
                  runtime = {
                     -- Tell the language server which version of Lua you're using
                     -- (most likely LuaJIT in the case of Neovim)
                     version = "LuaJIT",
                  },
                  -- Make the server aware of Neovim runtime files
                  workspace = {
                     checkThirdParty = false,
                     library = {
                        vim.env.VIMRUNTIME,
                        -- "${3rd}/luv/library"
                        -- "${3rd}/busted/library",
                     },
                     -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                     -- library = vim.api.nvim_get_runtime_file("", true)
                  },
               },
            })

            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
         end
         return true
      end,
   })
end

local function config_python()
   local lspconfig = require("lspconfig")
   lspconfig.pyright.setup({})
end

local function config_typescript()
   local lspconfig = require("lspconfig")
   lspconfig.tsserver.setup({})
end

local function config()
   -- See logs with `:LspInfo` and `:LspLog`
   vim.lsp.set_log_level("debug")

   config_lua()
   config_python()
   config_typescript()

   -- Global mappings.
   -- See `:help vim.diagnostic.*` for documentation on any of the below functions
   vim.keymap.set("n", "<space>le", vim.diagnostic.open_float, { desc = "Open Float" })
   vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to Previous" })
   vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to Next" })
   vim.keymap.set("n", "<space>lq", vim.diagnostic.setloclist, { desc = "Set Loc List" })

   -- Use LspAttach autocommand to only map the following keys
   -- after the language server attaches to the current buffer
   vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
         -- Enable completion triggered by <c-x><c-o>
         vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

         -- Buffer local mappings.
         -- See `:help vim.lsp.*` for documentation on any of the below functions
         local opts = { buffer = ev.buf, desc = "LspPlacholder" }
         vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
         vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
         vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
         vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
         vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
         vim.keymap.set("n", "<space>lwa", vim.lsp.buf.add_workspace_folder, opts)
         vim.keymap.set("n", "<space>lwr", vim.lsp.buf.remove_workspace_folder, opts)
         vim.keymap.set(
            "n",
            "<space>lwl",
            function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
            opts
         )
         vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
         vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
         vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
         vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
         vim.keymap.set("n", "<space>f", function() vim.lsp.buf.format({ async = true }) end, opts)
      end,
   })
end

return {
   "neovim/nvim-lspconfig",
   dependencies = {
      -- {
      --   "AstroNvim/astrolsp",
      --   opts = function(_, opts)
      --     local maps = opts.mappings
      --     maps.n["<Leader>li"] =
      --       { "<Cmd>LspInfo<CR>", desc = "LSP information", cond = function() return vim.fn.exists ":LspInfo" > 0 end }
      --   end,
      -- },

      -- -- Automatically install LSPs to stdpath for neovim
      -- {
      --   "williamboman/mason-lspconfig.nvim",
      --   dependencies = { "williamboman/mason.nvim" },
      --   cmd = { "LspInstall", "LspUninstall" },
      --   init = function(plugin) require("astrocore").on_load("mason.nvim", plugin.name) end,
      --   opts = function(_, opts)
      --     if not opts.handlers then opts.handlers = {} end
      --     opts.handlers[1] = function(server) require("astrolsp").lsp_setup(server) end
      --   end,
      -- },

      -- Useful status updates for LSP
      { "j-hui/fidget.nvim", opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      { "folke/neodev.nvim", lazy = true, opts = {} },
   },
   config = config,
}
