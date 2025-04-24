local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: See how TS/LSP mappings have changed:
--  https://gpanders.com/blog/whats-new-in-neovim-0-11/#more-default-mappings

later(function()
    add("neovim/nvim-lspconfig")

    -- FYI: see `:help lspconfig-all` or https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#angularls
    -- FYI: See mapping of server names here: https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
    vim.lsp.enable({
        "gopls",
        "lua_ls",
        "pyright",
        "ts_ls",
    })
end)
