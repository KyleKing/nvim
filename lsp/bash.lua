-- Install with: `mise use -g npm:bash-language-server`
-- Adapted from: https://github.com/neovim/nvim-lspconfig/blob/1a3a429efec62af632dfd8fa9b52fa226f655ec2/lsp/bashls.lua

---@type vim.lsp.Config
return {
    cmd = { "bash-language-server", "start" },
    settings = {
        bashIde = {
            -- Glob pattern for finding and parsing shell script files in the workspace.
            -- Used by the background analysis features across files.

            -- Prevent recursive scanning which will cause issues when opening a file
            -- directly in the home directory (e.g. ~/foo.sh).
            --
            -- Default upstream pattern is "**/*@(.sh|.inc|.bash|.command)".
            globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
        },
    },
    filetypes = { "bash", "sh" },
    root_markers = { ".git" },
}
