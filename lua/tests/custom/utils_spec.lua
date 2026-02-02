-- Test kyleking.utils module
local MiniTest = require("mini.test")
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["utils"] = MiniTest.new_set()

T["utils"]["utils module loads without errors"] = function()
    MiniTest.expect.no_error(function() require("kyleking.utils") end)
end

T["temp session detection"] = MiniTest.new_set()

T["temp session detection"]["detect_temp_session function exists"] = function()
    local utils = require("kyleking.utils")
    MiniTest.expect.equality(type(utils.detect_temp_session), "function", "detect_temp_session should be a function")
end

T["temp session detection"]["detects claude-prompt files as temp"] = function()
    local utils = require("kyleking.utils")

    -- Create a test buffer with claude-prompt pattern
    local bufnr = helpers.create_test_buffer({ "# Test" }, "markdown")
    vim.api.nvim_buf_set_name(bufnr, "/tmp/claude-prompt-test.md")
    vim.api.nvim_set_current_buf(bufnr)

    local is_temp, session_type, _ = utils.detect_temp_session()
    MiniTest.expect.equality(is_temp, true, "claude-prompt file should be detected as temp")
    MiniTest.expect.equality(session_type, "CLAUDE CODE EDITOR", "Should identify as Claude Code")

    helpers.delete_buffer(bufnr)
end

T["temp session detection"]["detects COMMIT_EDITMSG as temp"] = function()
    local utils = require("kyleking.utils")

    local bufnr = helpers.create_test_buffer({ "commit message" }, "gitcommit")
    vim.api.nvim_buf_set_name(bufnr, "/tmp/.git/COMMIT_EDITMSG")
    vim.api.nvim_set_current_buf(bufnr)

    local is_temp, session_type, _ = utils.detect_temp_session()
    MiniTest.expect.equality(is_temp, true, "COMMIT_EDITMSG should be detected as temp")
    MiniTest.expect.equality(session_type, "GIT COMMIT", "Should identify as git commit")

    helpers.delete_buffer(bufnr)
end

T["temp session detection"]["detects paths with .claude as temp"] = function()
    local utils = require("kyleking.utils")

    local bufnr = helpers.create_test_buffer({ "# Test" }, "markdown")
    vim.api.nvim_buf_set_name(bufnr, "/Users/test/.claude/projects/test.md")
    vim.api.nvim_set_current_buf(bufnr)

    local is_temp, session_type, _ = utils.detect_temp_session()
    MiniTest.expect.equality(is_temp, true, ".claude path should be detected as temp")
    MiniTest.expect.equality(session_type, "CLAUDE CODE EDITOR", "Should identify as Claude Code")

    helpers.delete_buffer(bufnr)
end

T["temp session detection"]["regular files are not temp"] = function()
    local utils = require("kyleking.utils")

    local bufnr = helpers.create_test_buffer({ "local x = 1" }, "lua")
    vim.api.nvim_buf_set_name(bufnr, "/Users/test/file.lua")
    vim.api.nvim_set_current_buf(bufnr)

    local is_temp, session_type, _ = utils.detect_temp_session()
    MiniTest.expect.equality(is_temp, false, "Regular file should not be detected as temp")
    MiniTest.expect.equality(session_type, "", "Session type should be empty")

    helpers.delete_buffer(bufnr)
end

T["filename utilities"] = MiniTest.new_set()

T["filename utilities"]["get_truncated_filename function exists"] = function()
    local utils = require("kyleking.utils")
    MiniTest.expect.equality(type(utils.get_truncated_filename), "function", "get_truncated_filename should be a function")
end

T["filename utilities"]["truncates long filenames"] = function()
    local utils = require("kyleking.utils")

    -- Create a buffer with a very long path
    local long_path = string.rep("/very_long_directory_name", 10) .. "/file.lua"
    local bufnr = helpers.create_test_buffer({ "test" }, "lua")
    vim.api.nvim_buf_set_name(bufnr, long_path)
    vim.api.nvim_set_current_buf(bufnr)

    local truncated = utils.get_truncated_filename()

    -- Should start with "..." if truncated
    if #long_path > 70 then
        MiniTest.expect.equality(truncated:sub(1, 3), "...", "Long path should be truncated with ...")
    end

    helpers.delete_buffer(bufnr)
end

T["highlight groups"] = MiniTest.new_set()

T["highlight groups"]["get_highlight_groups function exists"] = function()
    local utils = require("kyleking.utils")
    MiniTest.expect.equality(type(utils.get_highlight_groups), "function", "get_highlight_groups should be a function")
end

T["highlight groups"]["returns temp session highlight groups"] = function()
    local utils = require("kyleking.utils")

    local groups = utils.get_highlight_groups()
    MiniTest.expect.equality(type(groups), "table", "Should return a table of highlight groups")
    MiniTest.expect.equality(groups.TempSessionClaude ~= nil, true, "Should have TempSessionClaude group")
    MiniTest.expect.equality(groups.TempSessionGit ~= nil, true, "Should have TempSessionGit group")
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
