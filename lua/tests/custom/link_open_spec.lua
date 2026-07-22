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

local function set_line_and_open(line, ft)
    vim.cmd("enew")
    if ft then vim.bo.filetype = ft end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })

    local opened = nil
    local original_open = vim.ui.open
    vim.ui.open = function(target)
        opened = target
        return true
    end

    link_open.open()

    vim.ui.open = original_open
    return opened
end

-- Opens `line` as line `lnum` of a real file named `fname` (ft_resolvers keys on
-- the buffer's actual filename, so a renamed scratch buffer won't match).
local function open_in_named_file(fname, lines, lnum)
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    local path = dir .. "/" .. fname
    vim.fn.writefile(lines, path)

    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })

    local opened = nil
    local original_open = vim.ui.open
    vim.ui.open = function(target)
        opened = target
        return true
    end

    link_open.open()

    vim.ui.open = original_open
    vim.fn.delete(dir, "rf")
    return opened
end

T["open"] = MiniTest.new_set()

T["open"]["opens a plain URL"] = function()
    local opened = set_line_and_open("See https://example.com/path for details")
    MiniTest.expect.equality(opened, "https://example.com/path")
end

T["open"]["opens the URL portion of a markdown link"] = function()
    local opened = set_line_and_open("[Neovim docs](https://neovim.io/doc)")
    MiniTest.expect.equality(opened, "https://neovim.io/doc")
end

T["open"]["keeps parens inside a markdown link's URL"] = function()
    local opened = set_line_and_open("[tricky](https://example.com/a(b)c)")
    MiniTest.expect.equality(opened, "https://example.com/a(b)c")
end

T["open"]["resolves a plugin ref to its GitHub URL"] = function()
    local opened = set_line_and_open('add("echasnovski/mini.nvim")')
    MiniTest.expect.equality(opened, "https://github.com/echasnovski/mini.nvim")
end

T["open"]["resolves a plugin ref without a .nvim suffix but containing nvim"] = function()
    local opened = set_line_and_open('add("nvim-treesitter/nvim-treesitter")')
    MiniTest.expect.equality(opened, "https://github.com/nvim-treesitter/nvim-treesitter")
end

T["open"]["does not treat a generic word/word fragment as a plugin ref"] = function()
    local notified = false
    local original_notify = vim.notify
    vim.notify = function(msg, level)
        if level == vim.log.levels.WARN and msg:find("No link found") then notified = true end
    end

    set_line_and_open("Non-plugin path fragment: src/main")

    vim.notify = original_notify
    MiniTest.expect.equality(notified, true)
end

T["open"]["notifies when no link is found"] = function()
    local notified = false
    local original_notify = vim.notify
    vim.notify = function(msg, level)
        if level == vim.log.levels.WARN and msg:find("No link found") then notified = true end
    end

    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "no link here" })
    link_open.open()

    vim.notify = original_notify
    MiniTest.expect.equality(notified, true)
end

T["open"]["resolves an npm package from package.json"] = function()
    local opened = open_in_named_file("package.json", { "{", '  "lodash": "^4.17.21"', "}" }, 2)
    MiniTest.expect.equality(opened, "https://npmjs.com/package/lodash")
end

T["open"]["resolves a scoped npm package from package.json"] = function()
    local opened = open_in_named_file("package.json", { "{", '  "@babel/core": "^7.20.0"', "}" }, 2)
    MiniTest.expect.equality(opened, "https://npmjs.com/package/@babel/core")
end

T["open"]["resolves a PyPI package from requirements.txt"] = function()
    local opened = open_in_named_file("requirements.txt", { "requests==2.31.0" }, 1)
    MiniTest.expect.equality(opened, "https://pypi.org/project/requests")
end

T["open"]["resolves a bare (unversioned) package from requirements.txt"] = function()
    local opened = open_in_named_file("requirements.txt", { "click" }, 1)
    MiniTest.expect.equality(opened, "https://pypi.org/project/click")
end

T["open"]["does not treat a requirements.txt comment as a package"] = function()
    local opened = open_in_named_file("requirements.txt", { "# pinned for CVE-2024-1234" }, 1)
    MiniTest.expect.equality(opened, nil)
end

T["open"]["resolves a PyPI package from pyproject.toml, dropping the version specifier"] = function()
    local opened = open_in_named_file("pyproject.toml", { "dependencies = [", '  "pydantic>=2.0",', "]" }, 2)
    MiniTest.expect.equality(opened, "https://pypi.org/project/pydantic")
end

T["open"]["does not treat a Poetry-style pyproject.toml metadata line as a package"] = function()
    -- Poetry's `key = "value"` lines (version, description, ...) are quoted too, but the
    -- quote isn't the first non-whitespace char, unlike a bare list entry.
    local opened = open_in_named_file("pyproject.toml", { "[tool.poetry]", 'version = "0.1.0"' }, 2)
    MiniTest.expect.equality(opened, nil)
end

T["open"]["resolves a Homebrew formula from a Brewfile"] = function()
    local opened = open_in_named_file("Brewfile", { 'brew "ripgrep"' }, 1)
    MiniTest.expect.equality(opened, "https://formulae.brew.sh/formula/ripgrep")
end

-- Highlighting itself is covered by the "link highlighting" snapshot cases in
-- lua/tests/docs/hipatterns.snap (real highlight extmarks, not just resolver output).

if ... == nil then MiniTest.run() end

return T
