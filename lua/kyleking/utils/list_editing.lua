-- Minimal list editing for markdown and djot
-- Handles: list continuation, indent/unindent, blank lines for djot sublists

local M = {}

-- Detect if current line is a list item
-- Returns: marker, indent_len, content (or nil if not a list)
local function parse_list_line(line)
    -- Unordered lists: -, *, +
    local indent, marker, space, content = line:match("^(%s*)([%-%*%+])(%s+)(.*)$")
    if marker then return marker, #indent, content, "unordered" end

    -- Ordered lists: 1. 2) etc
    indent, marker, space, content = line:match("^(%s*)(%d+)([%.%)])(%s+)(.*)$")
    if marker then return marker .. space, #indent, content, "ordered" end

    return nil
end

-- Check if line is blank
local function is_blank(line) return line:match("^%s*$") ~= nil end

-- Handle Enter key in list context
function M.handle_return()
    local line = vim.api.nvim_get_current_line()
    local marker, indent_len, content = parse_list_line(line)

    if not marker then
        -- Not in a list, default behavior
        return "<CR>"
    end

    -- Empty list item - stop the list
    if content == "" or is_blank(content) then
        -- Delete the current line's list marker
        vim.api.nvim_set_current_line(string.rep(" ", indent_len))
        return "<End>"
    end

    -- Continue the list
    local indent = string.rep(" ", indent_len)
    local new_line = indent .. marker .. " "

    return "<CR>" .. vim.api.nvim_replace_termcodes(new_line, true, false, true)
end

-- Handle Tab key - indent list item
function M.handle_tab()
    local ft = vim.bo.filetype
    local line = vim.api.nvim_get_current_line()
    local marker, indent_len, content = parse_list_line(line)

    if not marker then return "<Tab>" end

    -- For djot, we need to check if previous line is blank
    if ft == "djot" then
        local row = vim.api.nvim_win_get_cursor(0)[1]
        if row > 1 then
            local prev_line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1]
            if prev_line and not is_blank(prev_line) then
                -- Insert blank line before indenting
                vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { "" })
                -- Move cursor down since we inserted a line
                vim.api.nvim_win_set_cursor(0, { row + 1, indent_len })
            end
        end
    end

    -- Indent by 2 spaces
    local new_indent = string.rep(" ", indent_len + 2)
    local new_line = new_indent .. marker .. " " .. content
    vim.api.nvim_set_current_line(new_line)

    -- Move cursor to after marker
    local col = #new_indent + #marker + 1
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col })

    return ""
end

-- Handle Shift-Tab - dedent list item
function M.handle_shift_tab()
    local line = vim.api.nvim_get_current_line()
    local marker, indent_len, content = parse_list_line(line)

    if not marker or indent_len < 2 then return "<S-Tab>" end

    -- Dedent by 2 spaces (minimum 0)
    local new_indent_len = math.max(0, indent_len - 2)
    local new_indent = string.rep(" ", new_indent_len)
    local new_line = new_indent .. marker .. " " .. content
    vim.api.nvim_set_current_line(new_line)

    -- Move cursor to after marker
    local col = #new_indent + #marker + 1
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col })

    return ""
end

-- Setup keymaps for list editing
function M.setup()
    local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { expr = true, buffer = true, desc = desc }) end

    -- Create autocmd for markdown and djot filetypes
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "djot" },
        callback = function()
            map("i", "<CR>", M.handle_return, "Continue list or stop on empty")
            map("i", "<Tab>", M.handle_tab, "Indent list item")
            map("i", "<S-Tab>", M.handle_shift_tab, "Dedent list item")
        end,
        group = vim.api.nvim_create_augroup("kyleking_list_editing", { clear = true }),
    })
end

return M
