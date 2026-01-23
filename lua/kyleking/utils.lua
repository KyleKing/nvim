local M = {}

-- Detect if current session is temporary (Claude Code, git commits, etc.)
-- Returns: is_temp_session, session_type, highlight_group
function M.detect_temp_session()
    local is_temp = false
    local session_type = ""
    local highlight_group = ""

    -- Check for Claude Code external editor
    if vim.env.CLAUDECODE == "1" then
        is_temp = true
        session_type = "CLAUDE CODE EDITOR"
        highlight_group = "TempSessionClaude"
        return is_temp, session_type, highlight_group
    end

    -- Check for git commit/rebase/merge files
    local filename = vim.fn.expand("%:t")
    if
        filename:match("^COMMIT_EDITMSG$")
        or filename:match("^MERGE_MSG$")
        or filename:match("^git%-rebase%-todo$")
        or filename:match("^%.git/")
    then
        is_temp = true
        session_type = "GIT COMMIT"
        highlight_group = "TempSessionGit"
    end

    return is_temp, session_type, highlight_group
end

return M
