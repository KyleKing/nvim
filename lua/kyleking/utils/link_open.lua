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

-- The url pattern's character class allows `(` `)` (so URLs like Wikipedia's
-- "...Lua_(programming_language)" survive), which means a bare URL wrapped in prose
-- parens -- "(see https://example.com)" -- or ended by sentence punctuation --
-- "https://example.com." -- greedily swallows the trailing char too. Trim it back off.
local function trim_trailing_punctuation(url)
    local open_count, close_count = 0, 0
    for c in url:gmatch("[()]") do
        if c == "(" then
            open_count = open_count + 1
        else
            close_count = close_count + 1
        end
    end
    while close_count > open_count and url:sub(-1) == ")" do
        url = url:sub(1, -2)
        close_count = close_count - 1
    end
    return (url:gsub("[.,;:!?]+$", ""))
end

-- Ordered list: most specific first
local resolvers = {
    { pat = M.patterns.md_link, resolve = function(m) return m:match("%((.*)%)$") end },
    { pat = M.patterns.url, resolve = trim_trailing_punctuation },
    { pat = M.patterns.plugin, resolve = function(m) return "https://github.com/" .. m end },
}

-- Filetype-aware resolvers checked first when the current file matches. Package name
-- capture stops at the first char outside `[%w._-]` so version specifiers/extras
-- (">=2.0", "^4.17", "[extra]") don't get swallowed into the match.
local ft_resolvers = {
    ["package%.json"] = { pat = '"([%w@][%w@./_-]*)"', base = "https://npmjs.com/package/" },
    ["requirements.*%.txt"] = { pat = "(%w[%w._-]*)", base = "https://pypi.org/project/" },
    -- Anchored so the quote must open the line: matches PEP 621/uv/hatch-style bare
    -- list entries ('  "pydantic>=2.0",') but not Poetry's `key = "value"` metadata
    -- lines (version, description, ...), which would otherwise misresolve. Poetry's
    -- `key = "value"` *dependency* lines (e.g. `requests = "^2.31.0"`) are the same
    -- shape as that metadata, so a line-based regex can't tell them apart -- doing so
    -- safely would need the toml treesitter parser (already installed) to find the
    -- enclosing table and check its name ends in "dependencies".
    ["pyproject%.toml"] = { pat = '^%s*"(%w[%w._-]*)', base = "https://pypi.org/project/" },
    ["Brewfile"] = { pat = 'brew "(%w[%w._-]*)"', base = "https://formulae.brew.sh/formula/" },
}

local function ft_resolver()
    local fname = vim.fn.expand("%:t")
    for pat, r in pairs(ft_resolvers) do
        if fname:match(pat) then return r end
    end
end

local function open_url(url)
    local ok, err = vim.ui.open(url)
    if not ok then vim.notify("Failed to open " .. url .. ": " .. tostring(err), vim.log.levels.ERROR) end
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
            open_url(ftr.base .. m)
            return
        end
    end

    for _, r in ipairs(resolvers) do
        local m = line:match(r.pat)
        if m then
            open_url(r.resolve(m))
            return
        end
    end

    vim.notify("No link found on current line", vim.log.levels.WARN)
end

return M
