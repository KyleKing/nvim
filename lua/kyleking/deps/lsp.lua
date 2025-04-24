local MiniDeps = require("mini.deps")
local add, now, _later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- PLANNED: See how TS/LSP mappings have changed:
--  https://gpanders.com/blog/whats-new-in-neovim-0-11/#more-default-mappings
now(function()
    add({ source = "neovim/nvim-lspconfig" })
    vim.lsp.enable({
        "gopls",
        "lua_ls",
        "pyright",
        "ts_ls",
    })
end)
