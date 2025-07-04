-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.nvim`" | redraw')
    local clone_cmd = {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/echasnovski/mini.nvim",
        mini_path,
    }
    vim.fn.system(clone_cmd)
    vim.cmd("packadd mini.nvim | helptags ALL")
    vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

require("mini.deps").setup()

require("kyleking.deps.bars-and-lines")
require("kyleking.deps.buffer")
require("kyleking.deps.color")
require("kyleking.deps.colorscheme")
require("kyleking.deps.completions")
require("kyleking.deps.editing-support")
require("kyleking.deps.file-explorer")
require("kyleking.deps.formatting")
require("kyleking.deps.fuzzy-finder")
require("kyleking.deps.git")
require("kyleking.deps.keybinding")
require("kyleking.deps.lsp")
require("kyleking.deps.motion")
require("kyleking.deps.search")
require("kyleking.deps.split-and-window")
require("kyleking.deps.syntax")
require("kyleking.deps.terminal-integration")
require("kyleking.deps.utility")

local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- now(function()
--     require("mini.notify").setup()
--     vim.notify = require("mini.notify").make_notify()
-- end)
-- now(function() require("mini.icons").setup() end)
-- now(function() require("mini.tabline").setup() end)
-- now(function() require("mini.statusline").setup() end)

-- later(function() require("mini.ai").setup() end)
-- later(function() require("mini.comment").setup() end)
-- later(function() require("mini.pick").setup() end)

-- Save Mini.Deps snapshot when run from config directory
later(function()
    if vim.fn.getcwd() == vim.fn.stdpath("config") then
        vim.defer_fn(function() vim.cmd("DepsSnapSave") end, 1000) -- 1 second delay
    end
end)
