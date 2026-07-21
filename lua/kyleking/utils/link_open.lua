-- Resolve and open links (URLs, markdown links, plugin refs, package refs) from the current line
local M = {}

-- Shared with mini.hipatterns (setup() rejects patterns with a real capture group --
-- "number expected, got string" -- so every pattern here must have zero captures;
-- `%b()` balances markdown-link parens without needing one).
M.patterns = {
    md_link = "%[.-%]%b()",
    url = "https?://[%w_.~:/?#%[%]@!$&'()*+,;=%%-]+",
    -- author/repo where repo name contains "nvim" (e.g. mini.nvim, nvim-treesitter,
    -- highlight-undo.nvim) -- restricting to "nvim" avoids false positives on generic
    -- word/word fragments (paths, division-like expressions, etc.)
    plugin = "[%w][%-_%w]+/[%-_.%w]*nvim[%-_.%w]*",
}

-- Ordered list: most specific first
local resolvers = {
    { pat = M.patterns.md_link, resolve = function(m) return m:match("%((.*)%)$") end },
    { pat = M.patterns.url, resolve = function(m) return m end },
    { pat = M.patterns.plugin, resolve = function(m) return "https://github.com/" .. m end },
}

-- Filetype-aware resolvers checked first when the current file matches. Package name
-- capture stops at the first char outside `[%w._-]` so version specifiers/extras
-- (">=2.0", "^4.17", "[extra]") don't get swallowed into the match.
local ft_resolvers = {
    ["package%.json"] = { pat = '"([%w@][%w@./_-]*)"', base = "https://npmjs.com/package/" },
    ["requirements.*%.txt"] = { pat = "(%w[%w._-]*)", base = "https://pypi.org/project/" },
    ["pyproject%.toml"] = { pat = '"(%w[%w._-]*)', base = "https://pypi.org/project/" },
    ["Brewfile"] = { pat = 'brew "(%w[%w._-]*)"', base = "https://formulae.brew.sh/formula/" },
}

local function ft_resolver()
    local fname = vim.fn.expand("%:t")
    for pat, r in pairs(ft_resolvers) do
        if fname:match(pat) then return r end
    end
end

--- Resolve and open the link found on the current line (filetype-specific resolvers
--- checked first, then generic markdown-link/URL/plugin-ref resolvers). Comment lines
--- (`#...`) skip filetype resolution so they don't get misread as a package name.
function M.open()
    local line = vim.api.nvim_get_current_line()

    local ftr = not line:match("^%s*#") and ft_resolver() or nil
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
