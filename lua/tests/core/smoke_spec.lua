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

T["mini.deps startup"] = MiniTest.new_set()

T["mini.deps startup"]["no errors during two-stage execution"] = function()
    local result = vim.system({
        "nvim",
        "--headless",
        "-c",
        "lua vim.wait(3000, function() return false end)",
        "-c",
        "q",
    }, { text = true }):wait(10000)
    local output = (result.stdout or "") .. (result.stderr or "")
    local error_start = output:find("%(mini%.deps%) There were errors")
    MiniTest.expect.equality(error_start, nil, "mini.deps two-stage errors:\n" .. output)
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

T["plugin interactions"] = MiniTest.new_set()

local function assert_no_stderr_errors(result, label)
    local stderr = result.stderr
    local has_error = stderr:find("E%d+:") or stderr:find("Error executing") or stderr:find("stack traceback")
    MiniTest.expect.equality(has_error, nil, label .. " produced errors:\n" .. stderr)
end

T["plugin interactions"]["float windows do not trigger winsep errors"] = function()
    local result = helpers.nvim_interaction_test([[
        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buf, true, {
            relative = "editor", row = 5, col = 5, width = 40, height = 10,
        })
        vim.wait(100, function() return false end)
        vim.api.nvim_set_current_win(win)
        vim.wait(100, function() return false end)
        vim.api.nvim_win_close(win, true)
    ]])
    assert_no_stderr_errors(result, "Float window interaction")
end

T["plugin interactions"]["mini.files open and close without errors"] = function()
    local result = helpers.nvim_interaction_test([[
        local ok, mini_files = pcall(require, "mini.files")
        if ok and mini_files then
            pcall(mini_files.open)
            vim.wait(500, function() return false end)
            pcall(mini_files.close)
        end
    ]])
    assert_no_stderr_errors(result, "mini.files interaction")
end

T["plugin interactions"]["mini.pick can be invoked without errors"] = function()
    local result = helpers.nvim_interaction_test([[
        local ok, pick = pcall(require, "mini.pick")
        if ok and pick then
            pcall(pick.builtin.files, { tool = "git" })
            vim.wait(200, function() return false end)
            pcall(pick.stop)
        end
    ]])
    assert_no_stderr_errors(result, "mini.pick interaction")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
