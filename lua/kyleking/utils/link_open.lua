-- Resolve and open links (URLs, markdown links, plugin refs, package refs) from the current line
local M = {}

-- Patterns for extracting the link target via `string.match` (real capture groups).
-- mini.hipatterns needs its own `()`-position-marker variants (see hl_patterns below);
-- passing a real capture group to hipatterns.setup() errors ("number expected, got string").
M.patterns = {
    md_link = "%[.-%]%((.-)%)",
    url = "https?://[%w_.~:/?#%[%]@!$&'()*+,;=%%-]+",
    -- author/repo where repo name contains "nvim" (e.g. mini.nvim, nvim-treesitter,
    -- highlight-undo.nvim) -- restricting to "nvim" avoids false positives on generic
    -- word/word fragments (paths, division-like expressions, etc.)
    plugin = "[%w][%-_%w]+/[%-_.%w]*nvim[%-_.%w]*",
}

M.hl_patterns = {
    md_link = "%[.-%]%(()[^%s%)]-()%)",
    url = M.patterns.url,
    plugin = M.patterns.plugin,
}

-- Ordered list: most specific first
local resolvers = {
    { pat = M.patterns.md_link, resolve = function(m) return m end },
    { pat = M.patterns.url, resolve = function(m) return m end },
    { pat = M.patterns.plugin, resolve = function(m) return "https://github.com/" .. m end },
}

-- Filetype-aware resolvers checked first when the current file matches
local ft_resolvers = {
    ["package%.json"] = { pat = '"([%w@][%w./-]*)"', base = "https://npmjs.com/package/" },
    ["requirements.*%.txt"] = { pat = "([%w-]+)", base = "https://pypi.org/project/" },
    ["pyproject%.toml"] = { pat = '"([%w-]+)"', base = "https://pypi.org/project/" },
    ["Brewfile"] = { pat = 'brew "([%w-]+)"', base = "https://formulae.brew.sh/formula/" },
}

local function ft_resolver()
    local fname = vim.fn.expand("%:t")
    for pat, r in pairs(ft_resolvers) do
        if fname:match(pat) then return r end
    end
end

--- Resolve and open the link found on the current line (filetype-specific resolvers
--- checked first, then generic markdown-link/URL/plugin-ref resolvers).
function M.open()
    local line = vim.api.nvim_get_current_line()

    local ftr = ft_resolver()
    if ftr then
        local m = line:match(ftr.pat)
        if m then
            vim.ui.open(ftr.base .. m)
            return
        end
    end

    for _, r in ipairs(resolvers) do
        local m = line:match(r.pat)
        if m then
            vim.ui.open(r.resolve(m))
            return
        end
    end

    vim.notify("No link found on current line", vim.log.levels.WARN)
end

return M
