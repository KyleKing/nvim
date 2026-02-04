-- ty: Astral's fast Python type checker and LSP
-- Docs: https://docs.astral.sh/ty/
-- Installation: uvx --from ty ty --version

return {
    filetypes = { "python" },
    -- Root detection: prioritize pyproject.toml for mono-repos
    root_markers = function(fname)
        -- First try pyproject.toml (explicit Python project)
        local pyproject_root = vim.fs.root(fname, "pyproject.toml")
        if pyproject_root then return pyproject_root end

        -- Fall back to git root (mono-repo root)
        return vim.fs.root(fname, ".git")
    end,
    settings = {
        ty = {
            -- ty settings can be added here as the project matures
            -- Currently minimal configuration needed
        },
    },
}
