-- Diagnostic suppression comments (noqa-style)
-- For a comprehensive solution, see: https://github.com/chrisgrieser/nvim-rulebook

local M = {}

local tool_configs = {
    golangcilint = {
        style = "above",
        template = function(code) return "//nolint:" .. code end,
    },
    oxlint = {
        style = "above",
        template = function(code) return "// eslint-disable-next-line " .. code end,
    },
    pyright = {
        style = "inline",
        template = function(code) return "# pyright: ignore[" .. code .. "]" end,
    },
    ruff = {
        style = "inline",
        template = function(code) return "# noqa: " .. code end,
    },
    selene = {
        style = "above",
        template = function(code) return "-- selene: allow(" .. code .. ")" end,
    },
    shellcheck = {
        style = "above",
        template = function(code) return "# shellcheck disable=" .. code end,
    },
    stylelint = {
        style = "above",
        template = function(code) return "/* stylelint-disable-next-line " .. code .. " */" end,
    },
    yamllint = {
        style = "inline",
        template = function(_code) return "# yamllint disable-line" end,
    },
}

local file_ignore_configs = {
    golangcilint = function(code) return "//nolint:" .. code end,
    oxlint = function(code) return "/* eslint-disable " .. code .. " */" end,
    pyright = function(code) return "# pyright: ignore[" .. code .. "]" end,
    ruff = function(code) return "# ruff: noqa: " .. code end,
    selene = function(code) return "-- selene: allow(" .. code .. ")" end,
    shellcheck = function(code) return "# shellcheck disable=" .. code end,
    stylelint = function(code) return "/* stylelint-disable " .. code .. " */" end,
    yamllint = function(_code) return "# yamllint disable" end,
}

local function _get_diagnostics_at_line(bufnr, line)
    local diags = vim.diagnostic.get(bufnr, { lnum = line })
    local matched = {}
    for _, d in ipairs(diags) do
        local source = d.source and d.source:lower():gsub("[%-%.%s]", "") or nil
        if source and tool_configs[source] and d.code then
            table.insert(matched, { diagnostic = d, source = source, code = tostring(d.code) })
        end
    end
    return matched
end

local function _insert_comment(bufnr, line, source, code)
    local config = tool_configs[source]
    if not config then return end

    local comment = config.template(code)
    if config.style == "inline" then
        local current = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
        vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, { current .. "  " .. comment })
    else
        local indent = (vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""):match("^(%s*)")
        vim.api.nvim_buf_set_lines(bufnr, line, line, false, { indent .. comment })
    end
end

function M.ignore_inline()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local matched = _get_diagnostics_at_line(bufnr, line)

    if #matched == 0 then
        vim.notify("No suppressible diagnostics on this line", vim.log.levels.INFO)
        return
    end

    if #matched == 1 then
        _insert_comment(bufnr, line, matched[1].source, matched[1].code)
        return
    end

    local items = {}
    for _, m in ipairs(matched) do
        table.insert(items, m.source .. ": " .. m.code .. " - " .. m.diagnostic.message)
    end
    vim.ui.select(items, { prompt = "Select diagnostic to suppress:" }, function(_, idx)
        if idx then _insert_comment(bufnr, line, matched[idx].source, matched[idx].code) end
    end)
end

function M.ignore_file()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local matched = _get_diagnostics_at_line(bufnr, line)

    if #matched == 0 then
        vim.notify("No suppressible diagnostics on this line", vim.log.levels.INFO)
        return
    end

    local function _insert_file_ignore(source, code)
        local template = file_ignore_configs[source]
        if not template then return end

        local insert_line = 0
        local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
        if first:match("^#!") or first:match("^%-%-.*coding") then insert_line = 1 end

        vim.api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, { template(code) })
    end

    if #matched == 1 then
        _insert_file_ignore(matched[1].source, matched[1].code)
        return
    end

    local items = {}
    for _, m in ipairs(matched) do
        table.insert(items, m.source .. ": " .. m.code .. " - " .. m.diagnostic.message)
    end
    vim.ui.select(items, { prompt = "Select diagnostic to suppress (file-wide):" }, function(_, idx)
        if idx then _insert_file_ignore(matched[idx].source, matched[idx].code) end
    end)
end

M._tool_configs = tool_configs

return M
