-- typed-jinja language server: static type checking for Jinja templates.
-- Installed from typed-jinja/editors/nvim. Uses the project's own venv binary
-- when present (uv projects), else falls back to typed-jinja-lsp on PATH.

return {
    cmd = function(dispatchers, config)
        local root = config.root_dir or vim.fn.getcwd()
        local venv = root .. "/.venv/bin/typed-jinja-lsp"
        local exe = (vim.uv or vim.loop).fs_stat(venv) and venv or "typed-jinja-lsp"
        return vim.lsp.rpc.start({ exe }, dispatchers)
    end,
    filetypes = { "jinja", "html.jinja" },
    root_markers = { "pyproject.toml", ".git" },
}
