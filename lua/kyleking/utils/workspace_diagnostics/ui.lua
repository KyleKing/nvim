-- ui: quickfix UI operations (picker, sessions)
local M = {}

M.qf = {}

-- Grouped quickfix picker with hierarchical display (file > items)
function M.qf.picker_grouped()
    local quickfix = require("kyleking.utils.workspace_diagnostics.quickfix")
    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify("Quickfix list is empty", vim.log.levels.WARN)
        return
    end

    local by_file = quickfix.qf.group_by_file()
    local items = {}
    local item_map = {}

    -- Build hierarchical display
    for file, entries in pairs(by_file) do
        local rel_path = vim.fn.fnamemodify(file, ":~:.")
        local group_line = string.format("▾ %s (%d)", rel_path, #entries)
        table.insert(items, group_line)
        item_map[group_line] = { is_group = true, file = file }

        for _, entry in ipairs(entries) do
            local severity_icon = ({ E = "E", W = "W", I = "I", N = " " })[entry.type] or " "
            local item_line = string.format(
                "  %s %d:%d  %s",
                severity_icon,
                entry.lnum,
                entry.col,
                (entry.text or ""):gsub("\n", " ")
            )
            table.insert(items, item_line)
            item_map[item_line] = { is_group = false, entry = entry, file = file }
        end
    end

    local MiniPick = require("mini.pick")
    MiniPick.start({
        source = {
            items = items,
            name = "Quickfix (grouped)",
            choose = function(item)
                if not item then return end
                local data = item_map[item]
                if not data then return end

                if data.is_group then
                    vim.cmd("edit " .. vim.fn.fnameescape(data.file))
                else
                    local entry = data.entry
                    if entry.bufnr > 0 then
                        vim.cmd("buffer " .. entry.bufnr)
                        vim.api.nvim_win_set_cursor(0, { entry.lnum, math.max(0, entry.col - 1) })
                    end
                end
            end,
            preview = function(item)
                if not item then return end
                local data = item_map[item]
                if not data then return end

                local file = data.file
                local lnum = data.is_group and 1 or data.entry.lnum

                return { file, lnum }
            end,
        },
    })
end

-- Save quickfix list to file
---@param filepath string|nil Path to save (defaults to .qf_session in cwd)
function M.qf.save_session(filepath)
    filepath = filepath or vim.fn.getcwd() .. "/.qf_session"

    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify("Quickfix list is empty", vim.log.levels.WARN)
        return
    end

    local data = {
        title = vim.fn.getqflist({ title = 0 }).title,
        items = qf,
    }

    local ok, encoded = pcall(vim.json.encode, data)
    if not ok then
        vim.notify("Failed to encode quickfix list", vim.log.levels.ERROR)
        return
    end

    local file = io.open(filepath, "w")
    if not file then
        vim.notify("Failed to open file: " .. filepath, vim.log.levels.ERROR)
        return
    end

    file:write(encoded)
    file:close()

    vim.notify(string.format("Saved %d items to %s", #qf, filepath), vim.log.levels.INFO)
end

-- Load quickfix list from file
---@param filepath string|nil Path to load (defaults to .qf_session in cwd)
function M.qf.load_session(filepath)
    filepath = filepath or vim.fn.getcwd() .. "/.qf_session"

    local file = io.open(filepath, "r")
    if not file then
        vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
        return
    end

    local content = file:read("*all")
    file:close()

    local ok, data = pcall(vim.json.decode, content)
    if not ok or not data then
        vim.notify("Failed to decode quickfix session", vim.log.levels.ERROR)
        return
    end

    vim.fn.setqflist({}, "r", { items = data.items, title = data.title or "Loaded session" })
    vim.cmd("copen")
    vim.notify(string.format("Loaded %d items from %s", #data.items, filepath), vim.log.levels.INFO)
end

return M
