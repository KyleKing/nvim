local M = {}

-- Get highlight group configurations using theme colors
function M.get_highlight_groups()
    local theme = require("kyleking.theme")
    local colors = theme.get_colors()

    return {
        TempModeCommand = { fg = colors.bg0, bg = colors.blue, bold = true },
        TempModeInsert = { fg = colors.bg0, bg = colors.green, bold = true },
        TempModeNormal = { fg = colors.bg0, bg = colors.fg1, bold = true },
        TempModeOther = { fg = colors.bg0, bg = colors.fg3, bold = true },
        TempModeReplace = { fg = colors.bg0, bg = colors.red, bold = true },
        TempModeVisual = { fg = colors.bg0, bg = colors.orange, bold = true },
        TempSessionClaude = { fg = colors.black, bg = colors.orange, bold = true },
        TempSessionGit = { fg = colors.black, bg = colors.green, bold = true },
    }
end

-- Get current mode info (label and highlight group)
function M.get_temp_mode_info()
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
    return mode_map[mode_code] or { label = " OTHER ", hl = "TempModeOther" }
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

-- Get truncated filename for statusline display with dynamic width
-- Calculates available space based on mode/session lengths when in temp session
function M.get_truncated_filename()
    local constants = require("kyleking.utils.constants")
    local full_path = vim.fn.expand("%:p")

    -- Check if in temp session to calculate precise reserved space
    local is_temp, session_type, _ = M.detect_temp_session()

    if is_temp then
        local mode_info = M.get_temp_mode_info()
        local abbreviated_session = M.get_abbreviated_session_type(session_type)

        -- Precise calculation: actual mode + session lengths
        local mode_width = #mode_info.label
        local session_width = #abbreviated_session + 2 -- " SESSION "
        local separators = 6 -- Spaces, %m, padding
        local reserved = mode_width + session_width + separators

        local columns = vim.o.columns
        local available = columns - reserved
        local min_width = constants.CHAR_LIMIT.FILENAME_MIN

        -- Use available space or fall back to minimum
        local max_width = math.max(min_width, available)

        if #full_path > max_width then
            local truncation_len = constants.CHAR_LIMIT.TRUNCATION_INDICATOR
            return ".../" .. string.sub(full_path, -(max_width - truncation_len))
        end
        return full_path
    else
        -- Non-temp session: simple truncation
        if #full_path > 70 then return "..." .. string.sub(full_path, -67) end
        return full_path
    end
end

-- Build temp session statusline string with current mode
function M.build_temp_statusline(session_type, session_hl_group)
    local mode_info = M.get_temp_mode_info()
    local abbreviated_session = M.get_abbreviated_session_type(session_type)

    return table.concat({
        "%#" .. mode_info.hl .. "#",
        mode_info.label,
        "%*",
        " ",
        "%{v:lua.require('kyleking.utils').get_truncated_filename()}",
        " %m",
        "%=",
        "%#" .. session_hl_group .. "#",
        " " .. abbreviated_session .. " ",
        "%*",
    }, "")
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

-- Toggle between focused and equal window layouts
-- Focused mode: active window gets larger share of space (60-70%), others share remainder equally
-- Equal mode: all windows get equal space
function M.toggle_window_focus()
    -- Skip if only one window
    local win_count = vim.fn.winnr("$")
    if win_count == 1 then
        vim.notify("Only one window open", vim.log.levels.INFO)
        return
    end

    -- Toggle state stored in global variable
    vim.g.window_focus_mode = not vim.g.window_focus_mode

    if vim.g.window_focus_mode then
        -- FOCUSED MODE: active window gets majority of space
        local total_lines = vim.o.lines - vim.o.cmdheight - 2 -- Account for statusline/tabline
        local total_cols = vim.o.columns

        -- Calculate ratios based on window count
        -- 2-3 windows: active gets 66%, others share 34%
        -- 4-5 windows: active gets 60%, others share 40%
        -- 6+ windows: active gets 50%, others share 50%
        local active_ratio = win_count <= 3 and 0.66 or win_count <= 5 and 0.60 or 0.50

        -- Minimum viable window size
        local min_height = 5
        local min_width = 20

        -- Calculate active window size
        local active_height = math.floor(total_lines * active_ratio)
        local active_width = math.floor(total_cols * active_ratio)

        -- Ensure minimum sizes for other windows
        local remaining_windows = win_count - 1
        local min_required_height = remaining_windows * min_height
        local min_required_width = remaining_windows * min_width

        -- Adjust if active window would make others too small
        if total_lines - active_height < min_required_height then active_height = total_lines - min_required_height end
        if total_cols - active_width < min_required_width then active_width = total_cols - min_required_width end

        -- Apply dimensions to active window
        vim.cmd("resize " .. active_height)
        vim.cmd("vertical resize " .. active_width)

        vim.notify("Focused layout (active window enlarged)", vim.log.levels.INFO)
    else
        -- EQUAL MODE: reset to equal sizing
        vim.cmd("wincmd =")
        vim.notify("Equal layout (all windows equal size)", vim.log.levels.INFO)
    end
end

return M
