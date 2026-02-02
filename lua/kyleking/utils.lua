local M = {}

-- Get highlight group configurations using theme colors
function M.get_highlight_groups()
    local theme = require("kyleking.theme")
    local colors = theme.get_colors()

    return {
        TempSessionClaude = { fg = colors.black, bg = colors.orange, bold = true },
        TempSessionGit = { fg = colors.black, bg = colors.green, bold = true },
        -- Mode-specific groups for temp sessions (reuse main statusline colors)
        TempModeNormal = { fg = colors.bg0, bg = colors.fg1, bold = true },
        TempModeInsert = { fg = colors.bg0, bg = colors.green, bold = true },
        TempModeVisual = { fg = colors.bg0, bg = colors.orange, bold = true },
        TempModeReplace = { fg = colors.bg0, bg = "#e06c75", bold = true },
        TempModeCommand = { fg = colors.bg0, bg = "#61afef", bold = true },
        TempModeOther = { fg = colors.bg0, bg = colors.fg3, bold = true },
    }
end

-- Get current mode indicator for statusline
function M.get_temp_mode_indicator()
    local mode_code = vim.api.nvim_get_mode().mode
    local mode_map = {
        ["n"] = { label = " NORMAL ", hl = "TempModeNormal" },
        ["no"] = { label = " NORMAL ", hl = "TempModeNormal" },
        ["nov"] = { label = " NORMAL ", hl = "TempModeNormal" },
        ["noV"] = { label = " NORMAL ", hl = "TempModeNormal" },
        ["i"] = { label = " INSERT ", hl = "TempModeInsert" },
        ["ic"] = { label = " INSERT ", hl = "TempModeInsert" },
        ["v"] = { label = " VISUAL ", hl = "TempModeVisual" },
        ["V"] = { label = " V-LINE ", hl = "TempModeVisual" },
        [""] = { label = " V-BLOCK ", hl = "TempModeVisual" },
        ["R"] = { label = " REPLACE ", hl = "TempModeReplace" },
        ["Rv"] = { label = " REPLACE ", hl = "TempModeReplace" },
        ["c"] = { label = " COMMAND ", hl = "TempModeCommand" },
        ["cv"] = { label = " COMMAND ", hl = "TempModeCommand" },
        ["ce"] = { label = " COMMAND ", hl = "TempModeCommand" },
        ["r"] = { label = " PROMPT ", hl = "TempModeOther" },
        ["rm"] = { label = " MORE ", hl = "TempModeOther" },
        ["t"] = { label = " TERMINAL ", hl = "TempModeOther" },
    }
    local mode_info = mode_map[mode_code] or { label = " OTHER ", hl = "TempModeOther" }
    return string.format("%%#%s#%s%%*", mode_info.hl, mode_info.label)
end

-- Get smart truncated filename for temp statusline (reserves min 40 chars)
function M.get_temp_truncated_filename()
    local constants = require("kyleking.utils.constants")
    local full_path = vim.fn.expand("%:p")
    local filename_min = constants.FILENAME_MIN or 40

    -- Calculate available width (accounting for mode ~10, session badge ~10, padding)
    local win_width = vim.o.columns
    local reserved = 25 -- Space for mode, session badge, and padding
    local available = win_width - reserved

    -- If path fits or we have good space, show it all
    if #full_path <= available or available >= filename_min then
        if #full_path > available then
            -- Truncate from left, keeping rightmost part
            return ".../" .. string.sub(full_path, -(available - 4))
        end
        return full_path
    end

    -- Minimal case: just show what we can
    if #full_path > filename_min then return ".../" .. string.sub(full_path, -(filename_min - 4)) end
    return full_path
end

-- Get abbreviated session type label
function M.get_abbreviated_session_type(session_type)
    if session_type == "CLAUDE CODE EDITOR" then
        return "CLAUDE"
    elseif session_type == "GIT COMMIT" then
        return "GIT"
    else
        return session_type
    end
end

-- Get truncated filename for statusline display (max 100 chars)
-- DEPRECATED: Use get_temp_truncated_filename for temp sessions
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
