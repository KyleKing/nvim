-- Smoke tests to verify test infrastructure
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["test infrastructure"] = MiniTest.new_set()

T["test infrastructure"]["helpers module loads"] = function()
    MiniTest.expect.no_error(function() require("tests.helpers") end)
end

T["test infrastructure"]["helpers.create_test_buffer creates buffer"] = function()
    local lines = { "line 1", "line 2", "line 3" }
    local bufnr = helpers.create_test_buffer(lines)

    MiniTest.expect.equality(vim.api.nvim_buf_is_valid(bufnr), true)

    local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    MiniTest.expect.equality(#content, 3)
    MiniTest.expect.equality(content[1], "line 1")

    helpers.delete_buffer(bufnr)
end

T["test infrastructure"]["helpers.check_keymap finds existing keymap"] = function()
    -- Create a test keymap
    vim.keymap.set("n", "<leader>test123", "<cmd>echo 'test'<cr>", { desc = "Test keymap" })

    local exists, keymap = helpers.check_keymap("<leader>test123", "n", "Test keymap")
    MiniTest.expect.equality(exists, true)
    MiniTest.expect.equality(keymap.desc, "Test keymap")

    -- Clean up
    vim.keymap.del("n", "<leader>test123")
end

T["test infrastructure"]["helpers.wait_for_condition succeeds when condition met"] = function()
    local counter = 0
    local result = helpers.wait_for_condition(function()
        counter = counter + 1
        return counter >= 3
    end, 1000, 50)

    MiniTest.expect.equality(result, true)
    MiniTest.expect.equality(counter >= 3, true)
end

T["test infrastructure"]["helpers.wait_for_condition times out when condition not met"] = function()
    local result = helpers.wait_for_condition(function() return false end, 200, 50)

    MiniTest.expect.equality(result, false)
end

T["test infrastructure"]["helpers.create_temp_file creates file"] = function()
    local content = "test content\nline 2"
    local filepath = helpers.create_temp_file(content, "txt")

    MiniTest.expect.equality(vim.fn.filereadable(filepath), 1)

    local file = io.open(filepath, "r")
    if file then
        local read_content = file:read("*a")
        file:close()
        MiniTest.expect.equality(read_content, content)
    end

    helpers.cleanup_temp_file(filepath)
end

T["test infrastructure"]["helpers.is_plugin_loaded detects loaded plugins"] = function()
    MiniTest.expect.equality(helpers.is_plugin_loaded("mini.test"), true)
    MiniTest.expect.equality(helpers.is_plugin_loaded("nonexistent_plugin_xyz"), false)
end

T["nvim configuration"] = MiniTest.new_set()

T["nvim configuration"]["nvim version is 0.11+"] = function()
    local version = vim.version()
    MiniTest.expect.equality(version.major >= 0, true)
    if version.major == 0 then MiniTest.expect.equality(version.minor >= 11, true) end
end

T["nvim configuration"]["config directory is accessible"] = function()
    local config_dir = vim.fn.stdpath("config")
    MiniTest.expect.equality(vim.fn.isdirectory(config_dir), 1)
end

T["nvim configuration"]["mini.nvim is installed"] = function()
    MiniTest.expect.no_error(function() require("mini.deps") end)
    MiniTest.expect.no_error(function() require("mini.test") end)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
