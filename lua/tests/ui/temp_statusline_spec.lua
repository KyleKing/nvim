-- Test temp session statusline (Claude Code, git commits)
local MiniTest = require("mini.test")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            -- Clean up before each test
        end,
    },
})

T["temp session statusline"] = MiniTest.new_set()

T["temp session statusline"]["mode info function returns label and highlight"] = function()
    local utils = require("kyleking.utils")

    -- Test mode info in normal mode
    local mode_info = utils.get_temp_mode_info()

    -- Should return a table with label and hl
    MiniTest.expect.equality(type(mode_info), "table", "Mode info should return table")
    MiniTest.expect.equality(type(mode_info.label), "string", "Mode info should have label string")
    MiniTest.expect.equality(type(mode_info.hl), "string", "Mode info should have highlight group string")
    MiniTest.expect.equality(mode_info.hl:match("^TempMode") ~= nil, true, "Highlight group should start with TempMode")
end

T["temp session statusline"]["abbreviated session type returns short labels"] = function()
    local utils = require("kyleking.utils")

    local claude = utils.get_abbreviated_session_type("CLAUDE CODE EDITOR")
    MiniTest.expect.equality(claude, "CLAUDE", "Should abbreviate CLAUDE CODE EDITOR")

    local git = utils.get_abbreviated_session_type("GIT COMMIT")
    MiniTest.expect.equality(git, "GIT", "Should abbreviate GIT COMMIT")

    local other = utils.get_abbreviated_session_type("OTHER")
    MiniTest.expect.equality(other, "OTHER", "Should return unknown types as-is")
end

T["temp session statusline"]["filename truncation respects minimum width"] = function()
    local utils = require("kyleking.utils")

    -- Save original file
    local original_file = vim.fn.expand("%:p")

    -- Create a temp file with very long path
    local long_path = "/tmp/very/long/path/with/many/directories/to/test/truncation/behavior/file.lua"
    vim.fn.mkdir(vim.fn.fnamemodify(long_path, ":h"), "p")
    vim.fn.writefile({ "test" }, long_path)
    vim.cmd("edit " .. long_path)

    local truncated = utils.get_truncated_filename()

    -- Should contain truncation indicator or full path
    MiniTest.expect.equality(type(truncated), "string", "Should return string")

    -- If truncated, should start with .../
    if #long_path > 65 then
        MiniTest.expect.equality(
            truncated:match("^%.%.%./") ~= nil or truncated == long_path,
            true,
            "Long paths should be truncated with .../ prefix or shown in full"
        )
    end

    -- Cleanup
    vim.cmd("bdelete!")
    vim.fn.delete(long_path)
    if original_file ~= "" then vim.cmd("edit " .. original_file) end
end

T["temp session statusline"]["mode highlight groups are defined"] = function()
    -- Trigger temp session detection by creating a claude-prompt file
    local tmpfile = vim.fn.tempname() .. "/claude-prompt-test.md"
    vim.fn.mkdir(vim.fn.fnamemodify(tmpfile, ":h"), "p")
    vim.fn.writefile({ "test" }, tmpfile)

    -- Open in new buffer to trigger autocmd
    vim.cmd("edit " .. tmpfile)
    vim.wait(100) -- Wait for autocmd to execute

    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if is_temp then
        -- Check that temp mode highlight groups are defined
        local mode_hl_groups = {
            "TempModeNormal",
            "TempModeInsert",
            "TempModeVisual",
            "TempModeReplace",
            "TempModeCommand",
            "TempModeOther",
        }

        for _, hl_group in ipairs(mode_hl_groups) do
            local hl = vim.api.nvim_get_hl(0, { name = hl_group })
            MiniTest.expect.equality(next(hl) ~= nil, true, "Temp mode highlight group should be defined: " .. hl_group)

            -- Verify highlight has bg color (essential for visibility)
            if next(hl) ~= nil then
                MiniTest.expect.equality(
                    hl.bg ~= nil,
                    true,
                    "Highlight group should have background color: " .. hl_group
                )
            end
        end
    end

    -- Cleanup
    vim.cmd("bdelete!")
    vim.fn.delete(tmpfile)
end

T["temp session statusline"]["session badge highlight groups are defined"] = function()
    -- Trigger temp session detection
    local tmpfile = vim.fn.tempname() .. "/claude-prompt-test.md"
    vim.fn.mkdir(vim.fn.fnamemodify(tmpfile, ":h"), "p")
    vim.fn.writefile({ "test" }, tmpfile)

    vim.cmd("edit " .. tmpfile)
    vim.wait(100)

    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if is_temp then
        -- Check session badge highlight groups
        local session_hl_groups = {
            "TempSessionClaude",
            "TempSessionGit",
        }

        for _, hl_group in ipairs(session_hl_groups) do
            local hl = vim.api.nvim_get_hl(0, { name = hl_group })
            MiniTest.expect.equality(next(hl) ~= nil, true, "Session highlight group should be defined: " .. hl_group)
        end
    end

    -- Cleanup
    vim.cmd("bdelete!")
    vim.fn.delete(tmpfile)
end

T["temp session statusline"]["statusline is set in temp session"] = function()
    -- Create claude prompt file
    local tmpfile = vim.fn.tempname() .. "/claude-prompt-test.md"
    vim.fn.mkdir(vim.fn.fnamemodify(tmpfile, ":h"), "p")
    vim.fn.writefile({ "test" }, tmpfile)

    vim.cmd("edit " .. tmpfile)
    vim.wait(100)

    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if is_temp then
        local statusline = vim.o.statusline

        -- Should contain mode highlight group
        MiniTest.expect.equality(
            statusline:match("TempMode") ~= nil,
            true,
            "Statusline should contain mode highlight group"
        )

        -- Should contain filename call
        MiniTest.expect.equality(
            statusline:match("get_truncated_filename") ~= nil,
            true,
            "Statusline should contain filename function call"
        )

        -- Should contain session badge
        MiniTest.expect.equality(
            statusline:match("TempSession") ~= nil,
            true,
            "Statusline should contain session badge highlight"
        )
    end

    -- Cleanup
    vim.cmd("bdelete!")
    vim.fn.delete(tmpfile)
end

T["temp session statusline"]["git commit file triggers temp session"] = function()
    -- Create git commit message file
    local tmpfile = vim.fn.tempname() .. "/COMMIT_EDITMSG"
    vim.fn.mkdir(vim.fn.fnamemodify(tmpfile, ":h"), "p")
    vim.fn.writefile({ "test commit" }, tmpfile)

    vim.cmd("edit " .. tmpfile)
    vim.wait(100)

    local utils = require("kyleking.utils")
    local is_temp, session_type = utils.detect_temp_session()

    MiniTest.expect.equality(is_temp, true, "COMMIT_EDITMSG should trigger temp session")
    MiniTest.expect.equality(session_type, "GIT COMMIT", "Should detect as GIT COMMIT session")

    -- Check statusline is set with mode highlight
    local statusline = vim.o.statusline
    MiniTest.expect.equality(
        statusline:match("TempMode") ~= nil,
        true,
        "Git commit should have temp statusline with mode indicator"
    )

    -- Cleanup
    vim.cmd("bdelete!")
    vim.fn.delete(tmpfile)
end

T["temp session statusline"]["easy quit keymap is set in temp session"] = function()
    -- Create temp file
    local tmpfile = vim.fn.tempname() .. "/claude-prompt-test.md"
    vim.fn.mkdir(vim.fn.fnamemodify(tmpfile, ":h"), "p")
    vim.fn.writefile({ "test" }, tmpfile)

    vim.cmd("edit " .. tmpfile)
    vim.wait(100)

    local utils = require("kyleking.utils")
    local is_temp = utils.detect_temp_session()

    if is_temp then
        -- Check that <leader>q keymap is set for current buffer
        local keymap = vim.fn.maparg("<leader>q", "n", false, true)
        MiniTest.expect.equality(keymap ~= nil and keymap.buffer == 1, true, "<leader>q should be buffer-local")
    end

    -- Cleanup
    vim.cmd("bdelete!")
    vim.fn.delete(tmpfile)
end

-- For manual running
if ... == nil then MiniTest.run() end

return T
