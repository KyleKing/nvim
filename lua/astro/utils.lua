-- Subset of AstroNvim Core Utilities
-- From: https://github.com/AstroNvim/astrocore/blob/af8311f2002ad6e2735fa3a72590e799d64e514a/lua/astrocore/init.lua
--
-- This module can be loaded with `local astro = require "astro.utils"`
--
-- copyright 2023
-- license GNU General Public License v3.0
--
local M = {}

-- TODO: remove any unused logic and/or simplify what is kept

--- Merge extended options with a default table of options
---@param default? table The default table that you want to merge into
---@param opts? table The new options that should be merged with the default table
---@return table # The merged table
function M.extend_tbl(default, opts)
    opts = opts or {}
    return default and vim.tbl_deep_extend("force", default, opts) or opts
end

--- Sync Lazy and then update Mason
function M.update_packages()
    require("lazy").sync({ wait = true })
    require("astrocore.mason").update_all()
end

--- Insert one or more values into a list like table and maintain that you do not insert non-unique values (THIS MODIFIES `lst`)
---@param lst any[]|nil The list like table that you want to insert into
---@param ... any Values to be inserted
---@return any[] # The modified list like table
function M.list_insert_unique(lst, ...)
    if not lst then lst = {} end
    assert(vim.tbl_islist(lst), "Provided table is not a list like table")
    local added = {}
    vim.tbl_map(function(v) added[v] = true end, lst)
    for _, val in ipairs({ ... }) do
        if not added[val] then
            table.insert(lst, val)
            added[val] = true
        end
    end
    return lst
end

--- Serve a notification with a title of AstroNvim
---@param msg string The notification body
---@param type integer|nil The type of the notification (:help vim.log.levels)
---@param opts? table The nvim-notify options to use (:help notify-options)
function M.notify(msg, type, opts)
    vim.schedule(function() vim.notify(msg, type, M.extend_tbl({ title = "AstroNvim" }, opts)) end)
end

--- Open a URL under the cursor with the current operating system
---@param path string The path of the file to open with the system opener
function M.system_open(path)
    vim.fn.jobstart(vim.fn.extend({ "open" }, { path or vim.fn.expand("<cfile>") }), { detach = true })
end

--- Run a shell command and capture the output and if the command succeeded or failed
---@param cmd string|string[] The terminal command to execute
---@param show_error? boolean Whether or not to show an unsuccessful command as an error to the user
---@return string|nil # The result of a successfully executed command or nil
function M.cmd(cmd, show_error)
    if type(cmd) == "string" then cmd = { cmd } end
    if vim.fn.has("win32") == 1 then cmd = vim.list_extend({ "cmd.exe", "/C" }, cmd) end
    local result = vim.fn.system(cmd)
    local success = vim.api.nvim_get_vvar("shell_error") == 0
    if not success and (show_error == nil or show_error) then
        vim.api.nvim_err_writeln(
            ("Error running command %s\nError message:\n%s"):format(table.concat(cmd, " "), result)
        )
    end
    return success and assert(result, "Result error"):gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "") or nil
end

return M
