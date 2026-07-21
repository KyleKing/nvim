# Plan: Replace url-open with native link opener

## Goal

Remove the `sontungexpt/url-open` third-party plugin (unmaintained, triggers `vim.validate{<table>}` deprecation warning) and replace it with a minimal custom implementation that uses `mini.hipatterns` for highlighting and `vim.ui.open()` (macOS `open`, nvim 0.10+) for opening.

## Context

- Nvim version: 0.12+ (macOS only, no cross-platform handling needed)
- Plugin manager: mini.deps (`now`/`later` pattern)
- `mini.operators` exchange is **disabled** (`prefix = ""`), so `gx` is free
- Current keymap: `<leader>uu` → `:URLOpenUnderCursor` (in `utility.lua:88`)
- `mini.hipatterns` is already loaded in `editing-support.lua:122–154`

## Deprecation warning being fixed

```
vim.validate{<table>} is deprecated
  url-open/lua/url-open/modules/options.lua:61
  triggered from lua/kyleking/deps/utility.lua:86
```

## Required features

1. Highlight URLs and openable links on all lines (not just current)
1. Open link from anywhere on current line (not just under cursor)
1. Resolve link types:
    - Plain URLs (`https://...`)
    - Markdown links `[text](url)` → open the URL portion
    - Neovim plugin refs `author/plugin.nvim` → `https://github.com/author/plugin.nvim`
    - npm packages (in `package.json` context) → `https://npmjs.com/package/<name>`
    - PyPI packages (in `requirements.txt` / `pyproject.toml` context) → `https://pypi.org/project/<name>`
    - Homebrew formulae (in `Brewfile` context) → `https://formulae.brew.sh/formula/<name>`
1. Extensible: easy to add new resolvers

## Implementation

### New file: `lua/kyleking/utils/link_open.lua`

Single module that owns both the pattern table and the open logic.

```lua
local M = {}

-- Shared with mini.hipatterns: define once, reference in both places
M.patterns = {
    md_link = "%[.-%]%((.-)%)",
    url     = "https?://[%w-._~:/?#%[%]@!$&'()*+,;=%%%%]+",
    plugin  = "[%w][-_%w]+/[-_%w]+%.nvim",  -- author/name.nvim (restricted suffix)
}

-- Ordered list: most specific first
local resolvers = {
    { name = "md_link", pat = M.patterns.md_link, resolve = function(m) return m end },
    { name = "url",     pat = M.patterns.url,     resolve = function(m) return m end },
    { name = "plugin",  pat = M.patterns.plugin,  resolve = function(m) return "https://github.com/" .. m end },
}

-- Filetype-aware resolvers checked first when filetype matches
local ft_resolvers = {
    -- filename match → { pattern, url prefix }
    ["package%.json"] = { pat = '"([%w@][%w./-]*)"',    base = "https://npmjs.com/package/" },
    ["requirements.*%.txt"] = { pat = "([%w-]+)",       base = "https://pypi.org/project/" },
    ["pyproject%.toml"] = { pat = '"([%w-]+)"',         base = "https://pypi.org/project/" },
    ["Brewfile"] = { pat = 'brew "([%w-]+)"',           base = "https://formulae.brew.sh/formula/" },
}

local function _ft_resolver()
    local fname = vim.fn.expand("%:t")
    for pat, r in pairs(ft_resolvers) do
        if fname:match(pat) then return r end
    end
end

function M.open()
    local line = vim.api.nvim_get_current_line()

    -- Try filetype-specific resolver first
    local ftr = _ft_resolver()
    if ftr then
        local m = line:match(ftr.pat)
        if m then
            vim.ui.open(ftr.base .. m)
            return
        end
    end

    -- Fall through to generic resolvers
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
```

### Changes to `lua/kyleking/deps/utility.lua`

Remove the entire `url-open` block (lines 84–89):

```lua
-- DELETE this block:
later(function()
    add("sontungexpt/url-open")
    require("url-open").setup({})
    local K = vim.keymap.set
    K("n", "<leader>uu", "<esc>:URLOpenUnderCursor<cr>", { desc = "Open URL" })
end)
```

Add a replacement keymap (no `add()` call — pure custom code):

```lua
later(function()
    local K = vim.keymap.set
    K("n", "gx",         function() require("kyleking.utils.link_open").open() end, { desc = "Open link" })
    K("n", "<leader>uu", function() require("kyleking.utils.link_open").open() end, { desc = "Open link" })
end)
```

Both `gx` (conventional) and `<leader>uu` (existing muscle memory) trigger the same function.

### Changes to `lua/kyleking/deps/editing-support.lua`

Add URL and markdown link highlighters to the existing `hipatterns.setup()` block (around line 128). Import the pattern table from the util module so patterns stay in sync:

```lua
later(function()
    local hipatterns = require("mini.hipatterns")
    local link_patterns = require("kyleking.utils.link_open").patterns  -- reuse

    -- ... existing word_pattern / paren_pattern helpers ...

    hipatterns.setup({
        highlighters = {
            -- existing keyword highlighters ...

            -- new link highlighters
            url = {
                pattern = link_patterns.url,
                group = "Underlined",
            },
            md_link = {
                -- highlight only the URL portion inside (...)
                pattern = link_patterns.md_link,
                group = "Underlined",
            },
            plugin_ref = {
                pattern = link_patterns.plugin,
                group = "Underlined",
            },
        },
    })
    -- ... rest unchanged ...
end)
```

## Notes

- The `plugin` pattern uses `%.nvim` suffix to avoid false positives on generic `foo/bar` path fragments. Plugins without `.nvim` suffix (e.g. `mini.nvim` itself is `echasnovski/mini.nvim`) still match because `%.nvim` matches `mini.nvim`. Consider also matching `-nvim` suffix: `"[%w][-_%w]+/[-_%w]+[.-]n?v?i?m?"` — evaluate during implementation.
- No `DepsUpdate` step needed — url-open is fully removed, not updated.
- Run `mise run test` after changes; the smoke test in `lua/tests/core/smoke_spec.lua` will catch any nil-rhs keymap errors from `later()` callbacks.
