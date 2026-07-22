-- Property-based fuzz testing for link_open: embed a known URL/plugin-ref/package name
-- amid random noise (or realistic surrounding syntax) and assert extraction is exact, or
-- feed pure noise and assert it never opens anything and never errors. Seeded for
-- reproducibility across CI runs. Iteration counts are kept modest -- for this kind of
-- deterministic pattern matching, more *shapes* catch more bugs than more *repetitions*
-- of the same shape.
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            vim.cmd("tabonly")
            vim.cmd("%bwipeout!")
        end,
    },
})

local link_open = require("kyleking.utils.link_open")

local SEED = 20260721
local ITERATIONS = 50

-- Deliberately excludes ':' '/' '[' ']' '(' ')' '=' '"' so noise alone can never assemble
-- a URL, markdown link, "author/repo" plugin ref, or quoted TOML/JSON value.
local NOISE_CHARSET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,;!?_-"

local function random_noise(max_len)
    local len = math.random(0, max_len)
    local chars = {}
    for i = 1, len do
        local idx = math.random(1, #NOISE_CHARSET)
        chars[i] = NOISE_CHARSET:sub(idx, idx)
    end
    local noise = table.concat(chars)
    -- Re-roll on the astronomically rare chance random letters spell "nvim".
    if noise:lower():find("nvim", 1, true) then return random_noise(max_len) end
    return noise
end

local function pick(pool) return pool[math.random(1, #pool)] end

local function open_current_buffer()
    local opened, warned = nil, nil
    local original_open, original_notify = vim.ui.open, vim.notify
    vim.ui.open = function(target)
        opened = target
        return true
    end
    vim.notify = function(msg, level)
        if level == vim.log.levels.WARN then warned = msg end
    end

    local ok, err = pcall(link_open.open)

    vim.ui.open, vim.notify = original_open, original_notify
    return ok, err, opened, warned
end

local function open_line(line)
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
    return open_current_buffer()
end

-- Reused across iterations of a single property (rewriting content each time) so
-- filetype-aware fuzz properties don't pay mkdir/delete cost per iteration.
local function open_line_in_file(path, line)
    vim.fn.writefile({ line }, path)
    vim.cmd("edit! " .. vim.fn.fnameescape(path))
    return open_current_buffer()
end

local URL_POOL = {
    "https://example.com",
    "https://example.com/path?query=1&x=2",
    "https://en.wikipedia.org/wiki/Lua_(programming_language)",
    "http://localhost:8080/api/v1",
}

local PLUGIN_POOL = {
    { frag = "echasnovski/mini.nvim", url = "https://github.com/echasnovski/mini.nvim" },
    { frag = "nvim-treesitter/nvim-treesitter", url = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { frag = "tzachar/highlight-undo.nvim", url = "https://github.com/tzachar/highlight-undo.nvim" },
}

-- How a plugin ref shows up under different nvim plugin managers/specs. The resolver is
-- purely text-pattern based (no awareness of call syntax), so all of these should resolve
-- identically -- this documents and guards that claim across managers used in this repo's
-- history (vim.pack, mini.deps) and common community ones (lazy.nvim, packer).
local PLUGIN_WRAPPERS = {
    function(frag) return 'add("' .. frag .. '")' end, -- mini.deps / vim.pack (string form)
    function(frag) return '{ source = "' .. frag .. '" }' end, -- vim.pack (table form)
    function(frag) return 'use("' .. frag .. '")' end, -- packer.nvim
    function(frag) return '{ "' .. frag .. '" }' end, -- lazy.nvim spec
    function(frag) return "See " .. frag .. " for details." end, -- bare prose mention
}

local PACKAGE_POOL = { "requests", "click", "pydantic" }

-- Version-specifier/extras variety a real requirements.txt or pyproject.toml list entry
-- can have around the bare package name.
local SUFFIX_VARIANTS = {
    function(name) return name end, -- no constraint
    function(name) return name .. "==2.31.0" end,
    function(name) return name .. ">=2.0" end,
    function(name) return name .. " >=2.0" end, -- space before constraint
    function(name) return name .. "[extra]>=2.0" end, -- extras
}

T["fuzz"] = MiniTest.new_set()

T["fuzz"]["extracts an embedded URL byte-for-byte regardless of surrounding noise"] = function()
    math.randomseed(SEED)
    for i = 1, ITERATIONS do
        local url = pick(URL_POOL)
        local line = random_noise(20) .. " " .. url .. " " .. random_noise(20)

        local ok, err, opened = open_line(line)
        local ctx = ("iteration %d\nline: %q"):format(i, line)
        MiniTest.expect.equality(ok, true, ctx .. "\nerror: " .. tostring(err))
        MiniTest.expect.equality(opened, url, ctx)
    end
end

T["fuzz"]["resolves a plugin ref to its GitHub URL across plugin-manager call styles"] = function()
    math.randomseed(SEED + 1)
    for i = 1, ITERATIONS do
        local plugin = pick(PLUGIN_POOL)
        local wrap = pick(PLUGIN_WRAPPERS)
        local line = random_noise(10) .. wrap(plugin.frag) .. random_noise(10)

        local ok, err, opened = open_line(line)
        local ctx = ("iteration %d\nline: %q"):format(i, line)
        MiniTest.expect.equality(ok, true, ctx .. "\nerror: " .. tostring(err))
        MiniTest.expect.equality(opened, plugin.url, ctx)
    end
end

T["fuzz"]["never errors and never fabricates a link on pure noise"] = function()
    math.randomseed(SEED + 2)
    for i = 1, ITERATIONS do
        local line = random_noise(20) .. random_noise(20)

        local ok, err, opened, warned = open_line(line)
        local ctx = ("iteration %d\nline: %q"):format(i, line)
        MiniTest.expect.equality(ok, true, ctx .. "\nerror: " .. tostring(err))
        MiniTest.expect.equality(opened, nil, ctx .. "\nunexpectedly opened: " .. tostring(opened))
        MiniTest.expect.equality(warned ~= nil, true, ctx)
    end
end

T["fuzz"]["resolves a requirements.txt package name across version/extras/comment variety"] = function()
    math.randomseed(SEED + 3)
    local path = vim.fn.tempname() .. "/requirements.txt"
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

    for i = 1, ITERATIONS do
        local name = pick(PACKAGE_POOL)
        local entry = pick(SUFFIX_VARIANTS)(name)
        -- Environment markers and inline comments are common requirements.txt suffixes.
        if math.random() < 0.5 then entry = entry .. '; python_version >= "3.8"' end
        if math.random() < 0.5 then entry = entry .. "  # " .. random_noise(10) end

        local ok, err, opened = open_line_in_file(path, entry)
        local ctx = ("iteration %d\nline: %q"):format(i, entry)
        MiniTest.expect.equality(ok, true, ctx .. "\nerror: " .. tostring(err))
        MiniTest.expect.equality(opened, "https://pypi.org/project/" .. name, ctx)
    end

    vim.fn.delete(vim.fn.fnamemodify(path, ":h"), "rf")
end

T["fuzz"]["resolves a pyproject.toml list-entry package name across version/extras variety"] = function()
    math.randomseed(SEED + 4)
    local path = vim.fn.tempname() .. "/pyproject.toml"
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

    for i = 1, ITERATIONS do
        local name = pick(PACKAGE_POOL)
        local entry = ('  "%s",'):format(pick(SUFFIX_VARIANTS)(name))

        local ok, err, opened = open_line_in_file(path, entry)
        local ctx = ("iteration %d\nline: %q"):format(i, entry)
        MiniTest.expect.equality(ok, true, ctx .. "\nerror: " .. tostring(err))
        MiniTest.expect.equality(opened, "https://pypi.org/project/" .. name, ctx)
    end

    vim.fn.delete(vim.fn.fnamemodify(path, ":h"), "rf")
end

if ... == nil then MiniTest.run() end

return T
