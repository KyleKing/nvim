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

--- A table to manage ToggleTerm terminals created by the user, indexed by the command run and then the instance number
---@type table<string,table<integer,table>>
M.user_terminals = {}

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

--- Partially reload AstroNvim user settings. Includes core vim options, mappings, and highlights. This is an experimental feature and may lead to instabilities until restart.
function M.reload()
   local was_modifiable = vim.opt.modifiable:get()

   local reload_module = require("plenary.reload").reload_module
   reload_module("astronivm.options")
   if package.loaded["config.options"] then reload_module("config.options") end

   if not was_modifiable then vim.opt.modifiable = true end
   local success, fault = pcall(require, "astronvim.options")
   if not success then vim.api.nvim_err_writeln("Failed to load " .. module .. "\n\n" .. fault) end
   if not was_modifiable then vim.opt.modifiable = false end
   local lazy = require("lazy")
   lazy.reload({ plugins = { M.get_plugin("astrocore") } })
   if M.is_available("astroui") then lazy.reload({ plugins = { M.get_plugin("astroui") } }) end
   vim.cmd.doautocmd("ColorScheme")
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

--- Toggle a user terminal if it exists, if not then create a new one and save it
---@param opts string|table A terminal command string or a table of options for Terminal:new() (Check toggleterm.nvim documentation for table format)
function M.toggle_term_cmd(opts)
   local terms = M.user_terminals
   -- if a command string is provided, create a basic table for Terminal:new() options
   if type(opts) == "string" then opts = { cmd = opts, hidden = true } end
   local num = vim.v.count > 0 and vim.v.count or 1
   -- if terminal doesn't exist yet, create it
   if not terms[opts.cmd] then terms[opts.cmd] = {} end
   if not terms[opts.cmd][num] then
      if not opts.count then opts.count = vim.tbl_count(terms) * 100 + num end
      if not opts.on_exit then opts.on_exit = function() terms[opts.cmd][num] = nil end end
      terms[opts.cmd][num] = require("toggleterm.terminal").Terminal:new(opts)
   end
   -- toggle the terminal
   terms[opts.cmd][num]:toggle()
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
      vim.api.nvim_err_writeln(("Error running command %s\nError message:\n%s"):format(table.concat(cmd, " "), result))
   end
   return success and assert(result, "Result error"):gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "") or nil
end

--- Get the first worktree that a file belongs to
---@param file string? the file to check, defaults to the current file
---@param worktrees table<string, string>[]? an array like table of worktrees with entries `toplevel` and `gitdir`, default retrieves from `vim.g.git_worktrees`
---@return table<string, string>|nil # a table specifying the `toplevel` and `gitdir` of a worktree or nil if not found
function M.file_worktree(file, worktrees)
   worktrees = worktrees or vim.g.git_worktrees
   if not worktrees then return end
   file = file or vim.fn.expand("%") --[[@as string]]
   for _, worktree in ipairs(worktrees) do
      if
         M.cmd({
            "git",
            "--work-tree",
            worktree.toplevel,
            "--git-dir",
            worktree.gitdir,
            "ls-files",
            "--error-unmatch",
            file,
         }, false)
      then
         return worktree
      end
   end
end

-- --- Setup and configure AstroCore
-- ---@param opts AstroCoreOpts
-- ---@see astrocore.config
-- function M.setup(opts)
--   M.config = vim.tbl_deep_extend("force", M.config, opts)

--   -- mappings
--   M.set_mappings(M.config.mappings)

--   -- autocmds
--   for augroup, autocmds in pairs(M.config.autocmds) do
--     if autocmds then
--       local augroup_id = vim.api.nvim_create_augroup(augroup, { clear = true })
--       for _, autocmd in ipairs(autocmds) do
--         local event = autocmd.event
--         autocmd.event = nil
--         autocmd.group = augroup_id
--         vim.api.nvim_create_autocmd(event, autocmd)
--         autocmd.event = event
--       end
--     end
--   end

--   -- user commands
--   for cmd, spec in pairs(M.config.commands) do
--     if spec then
--       local action = spec[1]
--       spec[1] = nil
--       vim.api.nvim_create_user_command(cmd, action, spec)
--       spec[1] = action
--     end
--   end

--   -- on_key hooks
--   for namespace, funcs in pairs(M.config.on_keys) do
--     if funcs then
--       local ns = vim.api.nvim_create_namespace(namespace)
--       for _, func in ipairs(funcs) do
--         vim.on_key(func, ns)
--       end
--     end
--   end

--   -- initialize rooter
--   if M.config.rooter then
--     local root_config = M.config.rooter --[[@as AstroCoreRooterOpts]]
--     vim.api.nvim_create_user_command(
--       "AstroRootInfo",
--       function() require("astrocore.rooter").info() end,
--       { desc = "Display rooter information" }
--     )
--     vim.api.nvim_create_user_command(
--       "AstroRoot",
--       function() require("astrocore.rooter").root() end,
--       { desc = "Run root detection" }
--     )

--     local group = vim.api.nvim_create_augroup("rooter", { clear = true }) -- clear the augroup no matter what
--     vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
--       nested = true,
--       group = group,
--       desc = "Root detection when entering a buffer",
--       callback = function(args)
--         if root_config.autochdir then require("astrocore.rooter").root(args.buf) end
--       end,
--     })
--     if vim.tbl_contains(root_config.detector or {}, "lsp") then
--       vim.api.nvim_create_autocmd("LspAttach", {
--         nested = true,
--         group = group,
--         desc = "Root detection on LSP attach",
--         callback = function(args)
--           if root_config.autochdir then
--             local server = assert(vim.lsp.get_client_by_id(args.data.client_id)).name
--             if not vim.tbl_contains(vim.tbl_get(root_config, "ignore", "servers") or {}, server) then
--               require("astrocore.rooter").root(args.buf)
--             end
--           end
--         end,
--       })
--     end
--   end
-- end

return M
