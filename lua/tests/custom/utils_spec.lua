local MiniTest = require("mini.test")
local helpers = require("tests.helpers")
local utils = require("kyleking.utils")

local T = MiniTest.new_set({ hooks = {} })

T["temp session detection"] = MiniTest.new_set()

T["temp session detection"]["detects temp sessions"] = function()
    local test_cases = {
        {
            path = "/tmp/claude-prompt-test.md",
            filetype = "markdown",
            expected = true,
            session_type = "CLAUDE CODE EDITOR",
        },
        { path = "/tmp/.git/COMMIT_EDITMSG", filetype = "gitcommit", expected = true, session_type = "GIT COMMIT" },
        {
            path = "/Users/test/.claude/projects/test.md",
            filetype = "markdown",
            expected = true,
            session_type = "CLAUDE CODE EDITOR",
        },
        { path = "/Users/test/file.lua", filetype = "lua", expected = false, session_type = "" },
    }

    for _, case in ipairs(test_cases) do
        local bufnr = helpers.create_test_buffer({ "test" }, case.filetype)
        vim.api.nvim_buf_set_name(bufnr, case.path)
        vim.api.nvim_set_current_buf(bufnr)

        local is_temp, session_type, _ = utils.detect_temp_session()
        MiniTest.expect.equality(is_temp, case.expected, case.path)
        MiniTest.expect.equality(session_type, case.session_type, case.path)

        helpers.delete_buffer(bufnr)
    end
end

T["filename utilities"] = MiniTest.new_set()

T["filename utilities"]["truncates long filenames"] = function()
    local long_path = string.rep("/very_long_directory_name", 10) .. "/file.lua"
    local bufnr = helpers.create_test_buffer({ "test" }, "lua")
    vim.api.nvim_buf_set_name(bufnr, long_path)
    vim.api.nvim_set_current_buf(bufnr)

    local truncated = utils.get_truncated_filename()
    if #long_path > 70 then MiniTest.expect.equality(truncated:sub(1, 3), "...", "Long path should be truncated") end

    helpers.delete_buffer(bufnr)
end

T["highlight groups"] = MiniTest.new_set()

T["highlight groups"]["returns expected groups"] = function()
    local groups = utils.get_highlight_groups()
    MiniTest.expect.equality(type(groups), "table")
    MiniTest.expect.equality(groups.TempSessionClaude ~= nil, true)
    MiniTest.expect.equality(groups.TempSessionGit ~= nil, true)
end

if ... == nil then MiniTest.run() end

return T
