return {
   -- LSP Configuration & Plugins
   "neovim/nvim-lspconfig",
   enabled = false, -- PLANNED: investigate
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

      -- -- Useful status updates for LSP
      -- -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      -- { "j-hui/fidget.nvim", opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      { "folke/neodev.nvim", lazy = true, opts = {} },
   },
   config = function(...) require("kyleking.plugins._configs.lsp")(...) end,
}
