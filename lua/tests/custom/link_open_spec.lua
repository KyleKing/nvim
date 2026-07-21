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

T["open"] = MiniTest.new_set()

T["open"]["opens a plain URL"] = function()
    local opened = set_line_and_open("See https://example.com/path for details")
    MiniTest.expect.equality(opened, "https://example.com/path")
end

T["open"]["opens the URL portion of a markdown link"] = function()
    local opened = set_line_and_open("[Neovim docs](https://neovim.io/doc)")
    MiniTest.expect.equality(opened, "https://neovim.io/doc")
end

T["open"]["resolves a plugin ref to its GitHub URL"] = function()
    local opened = set_line_and_open('add("echasnovski/mini.nvim")')
    MiniTest.expect.equality(opened, "https://github.com/echasnovski/mini.nvim")
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

if ... == nil then MiniTest.run() end

return T
