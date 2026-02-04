-- batch_fix: apply LSP code actions to quickfix items in batch
local M = {}

M.qf = {}

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
            -- Get diagnostics for the current line (nvim 0.11+ API)
            local line_diagnostics = vim.diagnostic.get(item.bufnr, { lnum = item.lnum - 1, severity = nil })
            params.context = { diagnostics = line_diagnostics }

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
                    -- Get diagnostics for the current line (nvim 0.11+ API)
                    local line_diagnostics = vim.diagnostic.get(item.bufnr, { lnum = item.lnum - 1, severity = nil })
                    params.context = { diagnostics = line_diagnostics }

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

return M
