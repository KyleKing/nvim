local M = {}

-- Get highlight group configurations using theme colors
function M.get_highlight_groups()
    local theme = require("kyleking.theme")
    local colors = theme.get_colors()

    return {
        TempSessionClaude = { fg = colors.black, bg = colors.orange, bold = true },
        TempSessionGit = { fg = colors.black, bg = colors.green, bold = true },
    }
end

-- Get truncated filename for statusline display (max 100 chars)
function M.get_truncated_filename()
    local full_path = vim.fn.expand("%:p")
    if #full_path > 70 then return "..." .. string.sub(full_path, -67) end
    return full_path
end

-- Detect if current session is temporary (Claude Code, git commits, etc.)
-- Returns: is_temp_session, session_type, highlight_group
function M.detect_temp_session()
    local is_temp = false
    local session_type = ""
    local highlight_group = ""

    local filename = vim.fn.expand("%:t")
    local filepath = vim.fn.expand("%:p")

    -- Check for Claude Code by filename/path pattern
    -- Patterns: claude-prompt-*.md files or paths containing /.claude/
    if filename:match("^claude%-prompt%-.+%.md$") or filepath:match("/%.?claude/") then
        is_temp = true
        session_type = "CLAUDE CODE EDITOR"
        highlight_group = "TempSessionClaude"
        return is_temp, session_type, highlight_group
    end

    -- Check for git commit/rebase/merge files
    if
        filename:match("^COMMIT_EDITMSG$")
        or filename:match("^MERGE_MSG$")
        or filename:match("^git%-rebase%-todo$")
        or filepath:match("%.git/")
    then
        is_temp = true
        session_type = "GIT COMMIT"
        highlight_group = "TempSessionGit"
    end

    return is_temp, session_type, highlight_group
end

return M
