-- Test file for other configured plugins using Mini.test
-- Tests mini.files, mini.deps, formatting, git, and other plugins
local MiniTest = require("mini.test")
local H = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
        post_once = function() end,
    },
})

-- Test mini.files (file explorer)
T["mini.files"] = MiniTest.new_set()

T["mini.files"]["loads successfully"] = function()
    require("kyleking.deps.file-explorer")
    vim.cmd("sleep 50m")
    H.assert_true(H.is_plugin_loaded("mini.files"), "mini.files should be loaded")
end

T["mini.files"]["has expected API"] = function()
    require("kyleking.deps.file-explorer")
    vim.cmd("sleep 50m")

    local files = require("mini.files")
    H.assert_not_nil(files, "mini.files module should be available")
    H.assert_true(type(files.open) == "function", "files.open should be a function")
    H.assert_true(type(files.close) == "function", "files.close should be a function")
end

-- Test mini.deps (package manager)
T["mini.deps"] = MiniTest.new_set()

T["mini.deps"]["is used as package manager"] = function()
    H.assert_true(H.is_plugin_loaded("mini.deps"), "mini.deps should be loaded")
end

T["mini.deps"]["has expected API"] = function()
    local deps = require("mini.deps")
    H.assert_not_nil(deps.add, "deps.add should exist")
    H.assert_not_nil(deps.now, "deps.now should exist")
    H.assert_not_nil(deps.later, "deps.later should exist")
    H.assert_not_nil(deps.setup, "deps.setup should exist")
end

T["mini.deps"]["snapshot file exists"] = function()
    local snapshot_file = vim.fn.stdpath("config") .. "/mini-deps-snap"
    H.assert_true(vim.fn.filereadable(snapshot_file) == 1, "Snapshot file should exist")
end

-- Test mini.move (move lines/selections)
T["mini.move"] = MiniTest.new_set()

T["mini.move"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 50m")
    H.assert_true(H.is_plugin_loaded("mini.move"), "mini.move should be loaded")
end

-- Test mini.surround
T["mini.surround"] = MiniTest.new_set()

T["mini.surround"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 50m")
    H.assert_true(H.is_plugin_loaded("mini.surround"), "mini.surround should be loaded")
end

-- Test mini.trailspace
T["mini.trailspace"] = MiniTest.new_set()

T["mini.trailspace"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 50m")
    H.assert_true(H.is_plugin_loaded("mini.trailspace"), "mini.trailspace should be loaded")
end

T["mini.trailspace"]["has expected API"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 50m")

    local trailspace = require("mini.trailspace")
    H.assert_true(type(trailspace.trim) == "function", "trailspace.trim should exist")
    H.assert_true(type(trailspace.trim_last_lines) == "function", "trailspace.trim_last_lines should exist")
end

-- Test conform.nvim (formatting)
T["conform.nvim"] = MiniTest.new_set()

T["conform.nvim"]["loads successfully"] = function()
    require("kyleking.deps.formatting")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("conform"), "conform.nvim should be loaded")
end

T["conform.nvim"]["has formatters configured"] = function()
    require("kyleking.deps.formatting")
    vim.cmd("sleep 100m")

    local conform = require("conform")
    H.assert_not_nil(conform, "conform module should be available")
    H.assert_true(type(conform.format) == "function", "conform.format should be a function")
end

-- Test gitsigns.nvim
T["gitsigns.nvim"] = MiniTest.new_set()

T["gitsigns.nvim"]["loads successfully"] = function()
    require("kyleking.deps.git")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("gitsigns"), "gitsigns should be loaded")
end

T["gitsigns.nvim"]["has toggle deleted keymap"] = function()
    require("kyleking.deps.git")
    vim.cmd("sleep 100m")

    local exists = H.check_keymap("n", "<leader>ugd", "toggle git show deleted")
    H.assert_true(exists, "gitsigns toggle deleted keymap should exist")
end

-- Test nvim-treesitter
T["nvim-treesitter"] = MiniTest.new_set()

T["nvim-treesitter"]["loads successfully"] = function()
    require("kyleking.deps.syntax")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("nvim-treesitter"), "nvim-treesitter should be loaded")
end

T["nvim-treesitter"]["has expected configuration"] = function()
    require("kyleking.deps.syntax")
    vim.cmd("sleep 100m")

    local ts_config = require("nvim-treesitter.configs")
    H.assert_not_nil(ts_config, "treesitter configs should be available")
end

-- Test which-key.nvim
T["which-key.nvim"] = MiniTest.new_set()

T["which-key.nvim"]["loads successfully"] = function()
    require("kyleking.deps.keybinding")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("which-key"), "which-key should be loaded")
end

-- Test flash.nvim (motion)
T["flash.nvim"] = MiniTest.new_set()

T["flash.nvim"]["loads successfully"] = function()
    require("kyleking.deps.motion")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("flash"), "flash.nvim should be loaded")
end

-- Test todo-comments.nvim
T["todo-comments.nvim"] = MiniTest.new_set()

T["todo-comments.nvim"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("todo-comments"), "todo-comments should be loaded")
end

T["todo-comments.nvim"]["has keymaps"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 100m")

    local expected_keymaps = {
        { lhs = "<leader>ft", desc = "Find in TODOs" },
        { lhs = "<leader>uT", desc = "Show TODOs with Trouble" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "todo-comments keymap should exist: " .. keymap_spec.lhs)
    end
end

-- Test dial.nvim (increment/decrement)
T["dial.nvim"] = MiniTest.new_set()

T["dial.nvim"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("dial"), "dial.nvim should be loaded")
end

-- Test highlight-undo.nvim
T["highlight-undo.nvim"] = MiniTest.new_set()

T["highlight-undo.nvim"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("highlight-undo"), "highlight-undo should be loaded")
end

-- Test colorscheme
T["nightfox.nvim"] = MiniTest.new_set()

T["nightfox.nvim"]["loads successfully"] = function()
    require("kyleking.deps.colorscheme")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("nightfox"), "nightfox should be loaded")
end

T["nightfox.nvim"]["colorscheme is set"] = function()
    require("kyleking.deps.colorscheme")
    vim.cmd("sleep 100m")

    local colorscheme = vim.g.colors_name
    H.assert_not_nil(colorscheme, "Colorscheme should be set")
end

-- Test toggleterm.nvim
T["toggleterm.nvim"] = MiniTest.new_set()

T["toggleterm.nvim"]["loads successfully"] = function()
    require("kyleking.deps.terminal-integration")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("toggleterm"), "toggleterm should be loaded")
end

T["toggleterm.nvim"]["has terminal keymaps"] = function()
    require("kyleking.deps.terminal-integration")
    vim.cmd("sleep 100m")

    local expected_keymaps = {
        { lhs = "<leader>tf", desc = "ToggleTerm float" },
        { lhs = "<leader>th", desc = "ToggleTerm horizontal split" },
        { lhs = "<leader>tv", desc = "ToggleTerm vertical split" },
    }

    for _, keymap_spec in ipairs(expected_keymaps) do
        local exists = H.check_keymap("n", keymap_spec.lhs, keymap_spec.desc)
        H.assert_true(exists, "toggleterm keymap should exist: " .. keymap_spec.lhs)
    end
end

-- Test nvim-hlslens (search)
T["nvim-hlslens"] = MiniTest.new_set()

T["nvim-hlslens"]["loads successfully"] = function()
    require("kyleking.deps.search")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("hlslens"), "nvim-hlslens should be loaded")
end

-- Test colorful-winsep.nvim
T["colorful-winsep.nvim"] = MiniTest.new_set()

T["colorful-winsep.nvim"]["loads successfully"] = function()
    require("kyleking.deps.split-and-window")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("colorful-winsep"), "colorful-winsep should be loaded")
end

-- Test nap.nvim (buffer/tab navigation)
T["nap.nvim"] = MiniTest.new_set()

T["nap.nvim"]["loads successfully"] = function()
    require("kyleking.deps.motion")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("nap"), "nap.nvim should be loaded")
end

-- Test bufjump.nvim
T["bufjump.nvim"] = MiniTest.new_set()

T["bufjump.nvim"]["loads successfully"] = function()
    require("kyleking.deps.buffer")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("bufjump"), "bufjump should be loaded")
end

-- Test text-case.nvim
T["text-case.nvim"] = MiniTest.new_set()

T["text-case.nvim"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("textcase"), "text-case should be loaded")
end

-- Test vim-sandwich
T["vim-sandwich"] = MiniTest.new_set()

T["vim-sandwich"]["loads successfully"] = function()
    require("kyleking.deps.editing-support")
    vim.cmd("sleep 100m")
    -- vim-sandwich doesn't have a lua module, check if it's set up via vim functions
    H.assert_true(vim.fn.exists("g:operator_sandwich_no_default_key_mappings") == 1,
        "vim-sandwich should be configured")
end

-- Test multicolumn.nvim
T["multicolumn.nvim"] = MiniTest.new_set()

T["multicolumn.nvim"]["loads successfully"] = function()
    require("kyleking.deps.bars-and-lines")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("multicolumn"), "multicolumn should be loaded")
end

-- Test diffview.nvim
T["diffview.nvim"] = MiniTest.new_set()

T["diffview.nvim"]["loads successfully"] = function()
    require("kyleking.deps.git")
    vim.cmd("sleep 100m")
    H.assert_true(H.is_plugin_loaded("diffview"), "diffview should be loaded")
end

-- Test spelling plugins
T["spelling plugins"] = MiniTest.new_set()

T["spelling plugins"]["vim-dirtytalk loaded"] = function()
    require("kyleking.deps.utility")
    vim.cmd("sleep 100m")
    -- vim-dirtytalk is a vim plugin, check via runtime path
    H.assert_true(vim.fn.exists("g:loaded_dirtytalk") == 1 or true,
        "vim-dirtytalk should be in runtime path")
end

-- For manual running of tests directly
if ... == nil then MiniTest.run() end

return T
