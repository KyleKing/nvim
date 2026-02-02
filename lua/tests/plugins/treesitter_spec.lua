-- Test nvim-treesitter and textobjects
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["treesitter"] = MiniTest.new_set()

T["treesitter"]["syntax module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.deps.syntax") end)
end

T["treesitter"]["nvim-treesitter is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(helpers.is_plugin_loaded("nvim-treesitter"), true, "nvim-treesitter should be loaded")
end

T["treesitter"]["treesitter config exists"] = function()
    vim.wait(1000)

    local ts_config = require("nvim-treesitter.configs")
    MiniTest.expect.equality(type(ts_config), "table", "Treesitter config should exist")
end

T["treesitter"]["common parsers are configured"] = function()
    vim.wait(1000)

    local ts_config = require("nvim-treesitter.configs")
    local config = ts_config.get_module("highlight") or {}

    -- Treesitter should be enabled
    MiniTest.expect.equality(config.enable, true, "Treesitter highlighting should be enabled")
end

T["treesitter"]["highlighting is enabled"] = function()
    vim.wait(1000)

    local ts_config = require("nvim-treesitter.configs")
    local highlight_config = ts_config.get_module("highlight") or {}

    MiniTest.expect.equality(highlight_config.enable, true, "Highlighting should be enabled")
end

T["treesitter"]["incremental selection is enabled"] = function()
    vim.wait(1000)

    local ts_config = require("nvim-treesitter.configs")
    local selection_config = ts_config.get_module("incremental_selection") or {}

    MiniTest.expect.equality(selection_config.enable, true, "Incremental selection should be enabled")
end

T["treesitter"]["indent is enabled"] = function()
    vim.wait(1000)

    local ts_config = require("nvim-treesitter.configs")
    local indent_config = ts_config.get_module("indent") or {}

    MiniTest.expect.equality(indent_config.enable, true, "Indent should be enabled")
end

T["treesitter"]["lua parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local lua_parser = parsers.has_parser("lua")

    MiniTest.expect.equality(lua_parser, true, "Lua parser should be installed")
end

T["treesitter"]["python parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local python_parser = parsers.has_parser("python")

    MiniTest.expect.equality(python_parser, true, "Python parser should be installed")
end

T["treesitter"]["javascript parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local js_parser = parsers.has_parser("javascript")

    MiniTest.expect.equality(js_parser, true, "JavaScript parser should be installed")
end

T["treesitter"]["typescript parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local ts_parser = parsers.has_parser("typescript")

    MiniTest.expect.equality(ts_parser, true, "TypeScript parser should be installed")
end

T["treesitter"]["markdown parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local md_parser = parsers.has_parser("markdown")

    MiniTest.expect.equality(md_parser, true, "Markdown parser should be installed")
end

T["treesitter"]["json parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local json_parser = parsers.has_parser("json")

    MiniTest.expect.equality(json_parser, true, "JSON parser should be installed")
end

T["treesitter"]["yaml parser is installed"] = function()
    vim.wait(1000)

    local parsers = require("nvim-treesitter.parsers")
    local yaml_parser = parsers.has_parser("yaml")

    MiniTest.expect.equality(yaml_parser, true, "YAML parser should be installed")
end

T["treesitter"]["can highlight lua code"] = function()
    vim.wait(1000)

    local bufnr = helpers.create_test_buffer({ "local x = 1", "print(x)" }, "lua")
    vim.api.nvim_set_current_buf(bufnr)

    -- Wait for highlighting to apply
    vim.wait(500)

    -- Check that treesitter is attached to the buffer
    local highlighter = vim.treesitter.highlighter.active[bufnr]
    MiniTest.expect.equality(highlighter ~= nil, true, "Treesitter highlighter should be attached to lua buffer")

    helpers.delete_buffer(bufnr)
end

T["treesitter-textobjects"] = MiniTest.new_set()

T["treesitter-textobjects"]["textobjects is configured"] = function()
    vim.wait(1000)
    MiniTest.expect.equality(
        helpers.is_plugin_loaded("nvim-treesitter-textobjects"),
        true,
        "textobjects should be loaded"
    )
end

T["treesitter-textobjects"]["textobjects module exists"] = function()
    vim.wait(1000)

    MiniTest.expect.no_error(
        function() require("nvim-treesitter-textobjects") end,
        "Textobjects module should load without error"
    )
end

T["incremental selection"] = MiniTest.new_set()

T["incremental selection"]["init_selection keymap is set"] = function()
    vim.wait(1000)

    -- Check that C-space is configured for init_selection
    local ts_config = require("nvim-treesitter.configs")
    local selection_config = ts_config.get_module("incremental_selection") or {}
    local keymaps = selection_config.keymaps or {}

    MiniTest.expect.equality(keymaps.init_selection, "<c-space>", "init_selection should be mapped to C-space")
end

T["incremental selection"]["node_incremental keymap is set"] = function()
    vim.wait(1000)

    local ts_config = require("nvim-treesitter.configs")
    local selection_config = ts_config.get_module("incremental_selection") or {}
    local keymaps = selection_config.keymaps or {}

    MiniTest.expect.equality(keymaps.node_incremental, "<c-space>", "node_incremental should be mapped to C-space")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
