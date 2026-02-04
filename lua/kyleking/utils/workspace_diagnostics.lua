-- workspace_diagnostics: run project-local type checkers and aggregate diagnostics
-- Supports mypy, pyright, and other CLI tools across monorepo sub-projects
local M = {}

local fre = require("find-relative-executable")

-- Tool-specific command builders (some tools need subcommands or special flags)
local tool_commands = {
    golangcilint = function(tool_path) return { tool_path, "run" } end,
    mypy = function(tool_path) return { tool_path, "--show-column-numbers", "--no-error-summary" } end,
    pyright = function(tool_path) return { tool_path, "--outputjson" } end,
    ruff = function(tool_path) return { tool_path, "check", "--output-format", "text" } end,
    selene = function(tool_path) return { tool_path, "--display-style", "quiet" } end,
    ty = function(tool_path) return { tool_path, "check" } end,
}

-- Get command for tool (with subcommands/flags if needed)
local function _get_tool_command(tool_name, tool_path)
    local builder = tool_commands[tool_name]
    if builder then return builder(tool_path) end
    return { tool_path }
end

-- Detect projects by marker file in a directory tree
---@param root_dir string Root directory to search
---@param marker string Marker file name (e.g., "pyproject.toml", "package.json")
---@param max_depth number|nil Maximum search depth (default: 3)
---@return string[] project_roots List of detected project directories
local function _find_projects_by_marker(root_dir, marker, max_depth)
    max_depth = max_depth or 3

    -- Use find command for better performance on large repos
    local cmd = string.format(
        "find %s -maxdepth %d -name %s -not -path '*/.venv/*' -not -path '*/node_modules/*' -not -path '*/__pycache__/*'",
        vim.fn.shellescape(root_dir),
        max_depth,
        vim.fn.shellescape(marker)
    )

    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then return {} end

    local projects = {}
    for line in result:gmatch("[^\n]+") do
        if line ~= "" then
            local project_root = vim.fn.fnamemodify(line, ":h")
            table.insert(projects, project_root)
        end
    end

    table.sort(projects) -- Consistent ordering
    return projects
end

-- Detect Python projects in a directory tree
---@param root_dir string Root directory to search
---@param max_depth number|nil Maximum search depth (default: 3)
---@return string[] project_roots List of detected Python project directories
local function _find_python_projects(root_dir, max_depth)
    return _find_projects_by_marker(root_dir, "pyproject.toml", max_depth)
end

-- Detect Node/TypeScript projects in a directory tree
---@param root_dir string Root directory to search
---@param max_depth number|nil Maximum search depth (default: 3)
---@return string[] project_roots List of detected Node project directories
local function _find_node_projects(root_dir, max_depth)
    return _find_projects_by_marker(root_dir, "package.json", max_depth)
end

-- Detect Go projects in a directory tree
---@param root_dir string Root directory to search
---@param max_depth number|nil Maximum search depth (default: 3)
---@return string[] project_roots List of detected Go project directories
local function _find_go_projects(root_dir, max_depth) return _find_projects_by_marker(root_dir, "go.mod", max_depth) end

-- Detect projects for a tool's ecosystem
---@param root_dir string Root directory to search
---@param tool_name string Tool name (to determine ecosystem)
---@return string[] project_roots List of detected project directories
local function _find_projects_for_tool(root_dir, tool_name)
    -- Tool to ecosystem mapping (from find-relative-executable)
    local ecosystems = {
        -- Python
        mypy = "python",
        pyright = "python",
        ty = "python",
        ruff = "python",
        black = "python",
        isort = "python",
        -- Node
        eslint = "node",
        eslint_d = "node",
        oxlint = "node",
        prettier = "node",
        prettierd = "node",
        biome = "node",
        stylelint = "node",
        -- Go
        golangcilint = "go",
        gofmt = "go",
        gofumpt = "go",
        -- Lua (global tools, return single project)
        selene = "lua",
        stylua = "lua",
    }

    local ecosystem = ecosystems[tool_name]
    if ecosystem == "python" then
        return _find_python_projects(root_dir)
    elseif ecosystem == "node" then
        return _find_node_projects(root_dir)
    elseif ecosystem == "go" then
        return _find_go_projects(root_dir)
    else
        -- Unknown ecosystem, return empty (will fall back to current project)
        return {}
    end
end

-- Run tool in a project directory and collect output
---@param tool_name string Tool to run (e.g., "mypy", "pyright")
---@param project_root string Project directory
---@param args string[]|nil Additional arguments (appended after tool-specific args)
---@return string|nil output Command output or nil if tool not found
local function _run_tool_in_project(tool_name, project_root, args)
    local tool_path = fre.resolve(tool_name, project_root)
    if not tool_path or vim.fn.executable(tool_path) ~= 1 then return nil end

    -- Build command with tool-specific flags
    local cmd = _get_tool_command(tool_name, tool_path)
    if args then vim.list_extend(cmd, args) end
    table.insert(cmd, ".")

    local result = vim.system(cmd, { cwd = project_root, text = true }):wait()
    return result.stdout and result.stdout ~= "" and result.stdout or result.stderr
end

-- Run tool across multiple projects (monorepo support)
---@param tool_name string Tool to run
---@param projects string[] List of project directories
---@param args string[]|nil Additional tool arguments
---@param callback function|nil Callback when complete (receives combined output)
function M.run_in_projects(tool_name, projects, args, callback)
    local outputs = {}
    local completed = 0
    local total = #projects

    if total == 0 then
        vim.notify("No projects found for " .. tool_name, vim.log.levels.WARN)
        return
    end

    vim.notify(string.format("Running %s in %d project(s)...", tool_name, total), vim.log.levels.INFO)

    for _, project_root in ipairs(projects) do
        vim.schedule(function()
            local output = _run_tool_in_project(tool_name, project_root, args)
            if output then table.insert(outputs, output) end

            completed = completed + 1
            if completed == total then
                local combined = table.concat(outputs, "\n")
                vim.fn.setqflist({}, "r", { title = tool_name .. " workspace", lines = vim.split(combined, "\n") })
                vim.cmd("copen")
                vim.notify(string.format("%s complete: %d items", tool_name, vim.fn.getqflist({ size = 0 }).size))

                if callback then callback(combined) end
            end
        end)
    end
end

-- Run tool in current project only
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_in_current_project(tool_name, args)
    local project_root = fre.get_current_project_root()

    -- Fallback to current working directory if no project root found
    if not project_root then
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= "" then
            project_root = vim.fn.fnamemodify(bufname, ":h")
            vim.notify(
                string.format("No project markers found, using buffer directory: %s", project_root),
                vim.log.levels.INFO
            )
        else
            project_root = vim.fn.getcwd()
            vim.notify(string.format("No project markers found, using cwd: %s", project_root), vim.log.levels.INFO)
        end
    end

    vim.notify(string.format("Running %s in %s...", tool_name, project_root), vim.log.levels.INFO)
    vim.schedule(function()
        local output = _run_tool_in_project(tool_name, project_root, args)
        if not output then
            vim.notify(tool_name .. " not found or produced no output", vim.log.levels.WARN)
            return
        end

        vim.fn.setqflist({}, "r", { title = tool_name .. " (current)", lines = vim.split(output, "\n") })
        vim.cmd("copen")
        vim.notify(string.format("%s complete: %d items", tool_name, vim.fn.getqflist({ size = 0 }).size))
    end)
end

-- Auto-detect and run tool across workspace/monorepo
-- Always runs in all projects within VCS root if available
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_workspace(tool_name, args)
    local vcs_info = fre.get_vcs_root()
    if vcs_info then
        -- Always search entire VCS root if available
        local projects = _find_projects_for_tool(vcs_info.root, tool_name)
        if #projects > 0 then
            M.run_in_projects(tool_name, projects, args)
            return
        end
    end
    -- Fallback to current project only if not in VCS or no projects found
    M.run_in_current_project(tool_name, args)
end

-- Quickfix batch operations
M.qf = {}

-- Filter quickfix list by pattern
---@param pattern string Pattern to match (vim regex)
---@param keep boolean If true, keep matches; if false, remove matches
function M.qf.filter(pattern, keep)
    local qf = vim.fn.getqflist()
    local filtered = {}

    for _, item in ipairs(qf) do
        local text = item.text or ""
        local matches = text:match(pattern) ~= nil
        if (keep and matches) or (not keep and not matches) then table.insert(filtered, item) end
    end

    vim.fn.setqflist(filtered, "r")
    vim.notify(string.format("Filtered: %d -> %d items", #qf, #filtered), vim.log.levels.INFO)
end

-- Group quickfix items by file
---@return table<string, table[]> items_by_file Map of filename to list of items
function M.qf.group_by_file()
    local qf = vim.fn.getqflist()
    local by_file = {}

    for _, item in ipairs(qf) do
        local filename = vim.fn.bufname(item.bufnr)
        if filename ~= "" then
            if not by_file[filename] then by_file[filename] = {} end
            table.insert(by_file[filename], item)
        end
    end

    return by_file
end

-- Show quickfix statistics
function M.qf.stats()
    local qf = vim.fn.getqflist()
    local by_file = M.qf.group_by_file()
    local by_type = { E = 0, W = 0, I = 0, N = 0 }

    for _, item in ipairs(qf) do
        local type = item.type ~= "" and item.type or "N"
        by_type[type] = (by_type[type] or 0) + 1
    end

    local lines = {
        "Quickfix Statistics:",
        string.format("  Total items: %d", #qf),
        string.format("  Files: %d", vim.tbl_count(by_file)),
        string.format("  Errors: %d | Warnings: %d | Info: %d | Other: %d", by_type.E, by_type.W, by_type.I, by_type.N),
    }

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Remove duplicate quickfix entries (same file + line + text)
function M.qf.dedupe()
    local qf = vim.fn.getqflist()
    local seen = {}
    local deduped = {}

    for _, item in ipairs(qf) do
        local key = string.format("%d:%d:%s", item.bufnr, item.lnum, item.text)
        if not seen[key] then
            seen[key] = true
            table.insert(deduped, item)
        end
    end

    vim.fn.setqflist(deduped, "r")
    vim.notify(string.format("Deduplicated: %d -> %d items", #qf, #deduped), vim.log.levels.INFO)
end

-- Sort quickfix list by file then line number
function M.qf.sort()
    local qf = vim.fn.getqflist()
    table.sort(qf, function(a, b)
        if a.bufnr ~= b.bufnr then return a.bufnr < b.bufnr end
        return a.lnum < b.lnum
    end)

    vim.fn.setqflist(qf, "r")
    vim.notify("Quickfix sorted by file + line", vim.log.levels.INFO)
end

-- Open all files in quickfix list
---@param split_cmd string|nil Split command ("vsplit", "split", "tabnew")
function M.qf.open_all(split_cmd)
    local by_file = M.qf.group_by_file()
    local files = vim.tbl_keys(by_file)
    table.sort(files)

    local cmd = split_cmd or "edit"
    for _, file in ipairs(files) do
        vim.cmd(cmd .. " " .. vim.fn.fnameescape(file))
    end

    vim.notify(string.format("Opened %d files", #files), vim.log.levels.INFO)
end

-- Filter quickfix list by severity type
---@param severity_type string|nil Severity type ("E", "W", "I", "N") or nil for all
function M.qf.filter_severity(severity_type)
    local qf = vim.fn.getqflist()
    local filtered = {}

    for _, item in ipairs(qf) do
        local item_type = item.type ~= "" and item.type or "N"
        if not severity_type or item_type == severity_type then table.insert(filtered, item) end
    end

    vim.fn.setqflist(filtered, "r")
    local label = severity_type and string.format("severity=%s", severity_type) or "all"
    vim.notify(string.format("Filtered to %s: %d -> %d items", label, #qf, #filtered), vim.log.levels.INFO)
end

-- Interactive severity filter with vim.ui.select
function M.qf.filter_severity_interactive()
    local choices = {
        { key = "e", label = "Errors only (E)", type = "E" },
        { key = "w", label = "Warnings only (W)", type = "W" },
        { key = "i", label = "Info only (I)", type = "I" },
        { key = "n", label = "Notes only (N)", type = "N" },
        { key = "a", label = "All (reset filter)", type = nil },
    }

    vim.ui.select(choices, {
        prompt = "Filter by severity:",
        format_item = function(item) return item.label end,
    }, function(choice)
        if choice then M.qf.filter_severity(choice.type) end
    end)
end

-- Group quickfix items by severity type
---@return table<string, table[]> items_by_type Map of type to list of items
function M.qf.group_by_type()
    local qf = vim.fn.getqflist()
    local by_type = {}

    for _, item in ipairs(qf) do
        local type = item.type ~= "" and item.type or "N"
        if not by_type[type] then by_type[type] = {} end
        table.insert(by_type[type], item)
    end

    return by_type
end

-- Apply LSP code actions to quickfix items (batch fix)
---@param opts table|nil Options: { filter = function(action) -> bool, preview = bool, mode = "auto"|"interactive"|"navigate" }
function M.qf.batch_fix(opts)
    opts = opts or {}
    local filter = opts.filter or function(action) return action.kind and action.kind:match("^quickfix") end
    local preview = opts.preview ~= false
    local mode = opts.mode or "auto"

    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify("Quickfix list is empty", vim.log.levels.WARN)
        return
    end

    if mode == "interactive" then
        M.qf._batch_fix_interactive(qf, filter)
    elseif mode == "navigate" then
        M.qf._batch_fix_navigate(qf, filter)
    else
        -- Auto mode with preview
        if preview then
            local msg = string.format("Apply code actions to %d quickfix items?", #qf)
            vim.ui.select({ "Yes", "No" }, { prompt = msg }, function(choice)
                if choice == "Yes" then M.qf._apply_batch_fixes(qf, filter) end
            end)
        else
            M.qf._apply_batch_fixes(qf, filter)
        end
    end
end

-- Internal: apply fixes to quickfix items
---@param qf_items table[] Quickfix items
---@param filter function Filter function for code actions
function M.qf._apply_batch_fixes(qf_items, filter)
    local fixed = 0
    local skipped = 0

    vim.notify("Applying fixes...", vim.log.levels.INFO)

    for _, item in ipairs(qf_items) do
        if item.bufnr > 0 and item.lnum > 0 then
            local ok = pcall(function()
                vim.api.nvim_buf_call(item.bufnr, function()
                    vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(0, item.col - 1) })

                    local params = vim.lsp.util.make_range_params()
                    params.context =
                        { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(item.bufnr, item.lnum - 1) }

                    local results = vim.lsp.buf_request_sync(item.bufnr, "textDocument/codeAction", params, 1000)
                    if not results then return end

                    for _, result in pairs(results) do
                        if result.result then
                            for _, action in ipairs(result.result) do
                                if filter(action) then
                                    vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
                                    fixed = fixed + 1
                                    return
                                end
                            end
                        end
                    end
                end)
            end)

            if not ok then skipped = skipped + 1 end
        else
            skipped = skipped + 1
        end
    end

    vim.notify(string.format("Batch fix complete: %d fixed, %d skipped", fixed, skipped), vim.log.levels.INFO)
end

-- Get available code actions for a quickfix item
---@param item table Quickfix item
---@return table[] actions Available code actions
local function _get_code_actions_for_item(item)
    if item.bufnr <= 0 or item.lnum <= 0 then return {} end

    local actions = {}
    local ok = pcall(function()
        vim.api.nvim_buf_call(item.bufnr, function()
            vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(0, item.col - 1) })

            local params = vim.lsp.util.make_range_params()
            params.context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics(item.bufnr, item.lnum - 1) }

            local results = vim.lsp.buf_request_sync(item.bufnr, "textDocument/codeAction", params, 1000)
            if results then
                for _, result in pairs(results) do
                    if result.result then vim.list_extend(actions, result.result) end
                end
            end
        end)
    end)

    return ok and actions or {}
end

-- Interactive batch fix: review each fix before applying
---@param qf_items table[] Quickfix items
---@param filter function Filter function for code actions
function M.qf._batch_fix_interactive(qf_items, filter)
    local current_idx = 1
    local fixed = 0
    local skipped = 0
    local apply_all = false
    local last_action_title = nil

    local function process_next()
        if current_idx > #qf_items then
            vim.notify(
                string.format("Interactive fix complete: %d fixed, %d skipped", fixed, skipped),
                vim.log.levels.INFO
            )
            return
        end

        local item = qf_items[current_idx]
        local filename = vim.fn.bufname(item.bufnr)
        local rel_path = vim.fn.fnamemodify(filename, ":~:.")

        -- Get available actions
        local actions = _get_code_actions_for_item(item)
        local matching_actions = vim.tbl_filter(filter, actions)

        if #matching_actions == 0 then
            skipped = skipped + 1
            current_idx = current_idx + 1
            vim.schedule(process_next)
            return
        end

        -- Jump to location
        vim.cmd("buffer " .. item.bufnr)
        vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(0, item.col - 1) })

        local action = matching_actions[1]
        local action_title = action.title or "Code action"

        -- Build prompt
        local prompt_lines = {
            string.format("[%d/%d] %s:%d", current_idx, #qf_items, rel_path, item.lnum),
            string.format("Diagnostic: %s", item.text or ""),
            string.format("Fix: %s", action_title),
        }

        -- Check if this is the same action as last time
        local show_apply_all = last_action_title and last_action_title == action_title
        last_action_title = action_title

        local choices = { "Apply", "Skip", "Apply to all remaining", "Cancel" }
        if not show_apply_all then table.remove(choices, 3) end

        vim.ui.select(choices, {
            prompt = table.concat(prompt_lines, "\n"),
            format_item = function(x) return x end,
        }, function(choice)
            if choice == "Apply" or apply_all then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
                fixed = fixed + 1
            elseif choice == "Skip" then
                skipped = skipped + 1
            elseif choice == "Apply to all remaining" then
                apply_all = true
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
                fixed = fixed + 1
            elseif choice == "Cancel" or not choice then
                vim.notify(string.format("Cancelled: %d fixed, %d skipped", fixed, skipped), vim.log.levels.INFO)
                return
            end

            current_idx = current_idx + 1
            vim.schedule(process_next)
        end)
    end

    vim.schedule(process_next)
end

-- Navigate mode: open buffers and provide keybindings for quick navigation
---@param qf_items table[] Quickfix items
---@param _filter function Filter function for code actions (unused)
function M.qf._batch_fix_navigate(qf_items, _filter)
    if #qf_items == 0 then return end

    -- Open all unique buffers
    local seen_buffers = {}
    for _, item in ipairs(qf_items) do
        if item.bufnr > 0 and not seen_buffers[item.bufnr] then seen_buffers[item.bufnr] = true end
    end

    local buffers = vim.tbl_keys(seen_buffers)
    table.sort(buffers)

    -- Load all buffers
    for _, bufnr in ipairs(buffers) do
        if vim.fn.bufloaded(bufnr) == 0 then vim.fn.bufload(bufnr) end
    end

    -- Jump to first item
    local first_item = qf_items[1]
    vim.cmd("buffer " .. first_item.bufnr)
    vim.api.nvim_win_set_cursor(0, { first_item.lnum, math.max(0, first_item.col - 1) })

    -- Create temporary buffer for instructions
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Batch Fix Navigation Mode",
        "",
        string.format("Total items: %d | Files: %d", #qf_items, #buffers),
        "",
        "Navigate:",
        "  ]q / [q     - Next/previous quickfix item",
        "  <leader>ca  - Apply code action at cursor",
        "  :copen      - Show full quickfix list",
        "",
        "Batch:",
        "  :lua require('kyleking.utils.workspace_diagnostics').qf.batch_fix({ mode = 'auto' })",
        "",
        "Close this window when done: :q",
    })

    -- Open in split
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, math.min(15, vim.api.nvim_buf_line_count(buf)))
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    vim.notify(string.format("Navigate mode: %d items across %d files", #qf_items, #buffers), vim.log.levels.INFO)
end

-- Grouped quickfix picker with hierarchical display (file > items)
function M.qf.picker_grouped()
    local qf = vim.fn.getqflist()
    if #qf == 0 then
        vim.notify("Quickfix list is empty", vim.log.levels.WARN)
        return
    end

    local by_file = M.qf.group_by_file()
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

-- Debug: show project root detection info
function M.debug_project_root()
    local bufname = vim.api.nvim_buf_get_name(0)
    local project_root = fre.get_current_project_root()
    local vcs_info = fre.get_vcs_root()
    local cwd = vim.fn.getcwd()

    local lines = {
        "Project Root Detection:",
        "  Buffer: " .. (bufname ~= "" and bufname or "(empty)"),
        "  Project root: " .. (project_root or "(not found)"),
        "  VCS root: " .. (vcs_info and (vcs_info.type .. ": " .. vcs_info.root) or "(not found)"),
        "  CWD: " .. cwd,
    }

    -- Show monorepo projects by ecosystem
    if vcs_info then
        local python_projects = _find_python_projects(vcs_info.root)
        local node_projects = _find_node_projects(vcs_info.root)
        local go_projects = _find_go_projects(vcs_info.root)

        local total = #python_projects + #node_projects + #go_projects
        if total > 1 then
            table.insert(lines, "\nMonorepo detected with " .. total .. " projects:")

            if #python_projects > 0 then
                table.insert(lines, "\n  Python projects (" .. #python_projects .. "):")
                for i, proj in ipairs(python_projects) do
                    local rel = proj:gsub("^" .. vim.pesc(vcs_info.root) .. "/", "")
                    table.insert(lines, "    " .. i .. ". " .. rel)
                end
            end

            if #node_projects > 0 then
                table.insert(lines, "\n  Node/TypeScript projects (" .. #node_projects .. "):")
                for i, proj in ipairs(node_projects) do
                    local rel = proj:gsub("^" .. vim.pesc(vcs_info.root) .. "/", "")
                    table.insert(lines, "    " .. i .. ". " .. rel)
                end
            end

            if #go_projects > 0 then
                table.insert(lines, "\n  Go projects (" .. #go_projects .. "):")
                for i, proj in ipairs(go_projects) do
                    local rel = proj:gsub("^" .. vim.pesc(vcs_info.root) .. "/", "")
                    table.insert(lines, "    " .. i .. ". " .. rel)
                end
            end
        end
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Run tool in current project only (skip monorepo detection)
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_current_only(tool_name, args) M.run_in_current_project(tool_name, args) end

-- Run tool in all monorepo projects (force monorepo mode)
---@param tool_name string Tool to run
---@param args string[]|nil Additional tool arguments
function M.run_all_projects(tool_name, args)
    local vcs_info = fre.get_vcs_root()
    if not vcs_info then
        vim.notify("No VCS root found", vim.log.levels.WARN)
        return
    end

    local projects = _find_projects_for_tool(vcs_info.root, tool_name)
    if #projects == 0 then
        vim.notify("No projects found for " .. tool_name, vim.log.levels.WARN)
        return
    end

    M.run_in_projects(tool_name, projects, args)
end

return M
