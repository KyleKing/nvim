-- Install with: `mise use -g lua-language-server`
-- Adapted from: https://github.com/neovim/nvim-lspconfig/blob/1a3a429efec62af632dfd8fa9b52fa226f655ec2/lsp/lua_ls.lua
-- And `:h lsp-quickstart`
-- Also consider 'emmylua_ls' from https://github.com/neovim/nvim-lspconfig/pull/3745

---@type vim.lsp.Config
return {
    cmd = { "lua-language-server" },
    root_markers = {
        ".luarc.json",
        ".luarc.jsonc",
        ".luacheckrc",
        ".stylua.toml",
        "stylua.toml",
        "selene.toml",
        "selene.yml",
        ".git",
    },
    filetypes = { "lua" },
    -- PLANNED: validating this schema should be possible. See:
    -- https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
    settings = {
        Lua = {
            addon_manager = { enable = false },
            format = { enable = false },
            hint = { enable = true },
            telemetry = { enable = true },
        },
    },
}
