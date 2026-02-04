-- statusline: mini.statusline configuration with profiles, caching, and async updates
local MiniDeps = require("mini.deps")
local later = MiniDeps.later

-- Check for temp session BEFORE scheduling later()
local utils = require("kyleking.utils")
local is_temp_session = utils.detect_temp_session()

if not is_temp_session then
    later(function()
        local MiniStatusline = require("mini.statusline")
        local project_tools = require("find-relative-executable")

        -- Statusline section cache with configurable TTLs
        -- Balance UI responsiveness with avoiding stale data
        local section_cache = {}
        local SECTION_CACHE_TTL_MS = 1000 -- Default sections: 1s (LSP, diagnostics change frequently)
        local BRANCH_CACHE_TTL_MS = 300000 -- Branch metadata: 5min (git operations are expensive, branches change slowly)

        local function cache_section(key, compute_fn, ttl_ms)
            ttl_ms = ttl_ms or SECTION_CACHE_TTL_MS
            local now_ts = vim.uv.hrtime() / 1000000
            local entry = section_cache[key]
            if entry and (now_ts - entry.timestamp) < ttl_ms then return entry.value end

            local value = compute_fn()
            section_cache[key] = { value = value, timestamp = now_ts }
            return value
        end

        -- Profile system: compact (minimal) vs info-dense (full context)
        local current_profile = "compact"
        local info_dense_timer = nil
        local INFO_DENSE_TIMEOUT_MS = 300000 -- Auto-revert info-dense: 5min (prevent cluttered statusline long-term)

        local profiles = {
            compact = {
                git_status = true,
                branch_metadata = false,
                workspace = false,
                lsp = false,
                lint = false,
                diagnostics = true,
            },
            ["info-dense"] = {
                git_status = true,
                branch_metadata = true,
                workspace = true,
                lsp = true,
                lint = true,
                diagnostics = true,
            },
        }

        -- Filetype-specific profile overrides (applied on top of base profile)
        local filetype_adjustments = {
            -- Writing/documentation: minimal distraction
            markdown = { workspace = false, lsp = false, lint = false, branch_metadata = false },
            text = { workspace = false, lsp = false, lint = false, branch_metadata = false },
            -- Development: full context
            python = { branch_metadata = true, workspace = true, lsp = true, lint = true },
            lua = { branch_metadata = true, workspace = true, lsp = true, lint = true },
            go = { branch_metadata = true, workspace = true, lsp = true, lint = true },
            rust = { branch_metadata = true, workspace = true, lsp = true, lint = true },
            typescript = { branch_metadata = true, workspace = true, lsp = true, lint = true },
            javascript = { branch_metadata = true, workspace = true, lsp = true, lint = true },
            -- Git operations: emphasize branch/PR
            gitcommit = { branch_metadata = true, workspace = false, lsp = false },
            gitrebase = { branch_metadata = true, workspace = false, lsp = false },
            -- Config files: show workspace for context
            json = { workspace = true },
            yaml = { workspace = true },
            toml = { workspace = true },
        }

        local function get_active_sections()
            local base = profiles[current_profile]
            local ft = vim.bo.filetype
            local adjustments = filetype_adjustments[ft] or {}
            return vim.tbl_extend("force", base, adjustments)
        end

        -- Load persistent profile state
        local state_file = vim.fn.stdpath("state") .. "/statusline-profile.txt"
        if vim.fn.filereadable(state_file) == 1 then
            local saved_profile = vim.trim(vim.fn.readfile(state_file)[1] or "")
            if saved_profile == "compact" or saved_profile == "info-dense" then current_profile = saved_profile end
        end

        local function save_profile_state() vim.fn.writefile({ current_profile }, state_file) end

        -- Workspace/project root display (cached)
        local function workspace_section()
            return cache_section("workspace:" .. vim.api.nvim_get_current_buf(), function()
                -- Try LSP client root first (most accurate for current buffer)
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                local root = clients[1] and clients[1].root_dir or project_tools.get_current_project_root()
                if not root then return "" end

                local name = vim.fn.fnamemodify(root, ":t")
                return name ~= "" and "󱧼 " .. name or ""
            end)
        end

        -- Enhanced branch metadata: branch name, PR info, ahead/behind, stash
        -- Supports both git and jj with GitHub PRs via gh CLI
        -- Uses async updates to prevent UI blocking
        local function branch_metadata_section()
            local vcs = project_tools.get_vcs_root(vim.api.nvim_buf_get_name(0))
            if not vcs then return "" end

            local cache_key = "branch_meta:" .. vcs.type .. ":" .. vcs.root
            local cached = section_cache[cache_key]
            local now_ts = vim.uv.hrtime() / 1000000

            -- Return cached value immediately if still valid
            if cached and (now_ts - cached.timestamp) < BRANCH_CACHE_TTL_MS then return cached.value end

            -- Start async update if cache is stale or missing
            if not cached or (now_ts - cached.timestamp) >= BRANCH_CACHE_TTL_MS then
                -- Return stale cache immediately (non-blocking)
                local stale_value = cached and cached.value or ""

                -- Update cache asynchronously
                vim.schedule(function()
                    local parts = {}

                    if vcs.type == "git" then
                        -- Get current branch name
                        vim.system({ "git", "branch", "--show-current" }, { cwd = vcs.root }, function(branch_result)
                            if branch_result.code == 0 and branch_result.stdout then
                                local branch = vim.trim(branch_result.stdout)
                                if branch ~= "" then
                                    table.insert(parts, " " .. branch)

                                    -- Get PR info via gh CLI (async)
                                    vim.system(
                                        { "gh", "pr", "view", "--json", "number,title" },
                                        { cwd = vcs.root },
                                        function(pr_result)
                                            if pr_result.code == 0 and pr_result.stdout and pr_result.stdout ~= "" then
                                                local ok, pr_data = pcall(vim.json.decode, pr_result.stdout)
                                                if ok and pr_data.number then
                                                    local title = pr_data.title:sub(1, 20)
                                                    if #pr_data.title > 20 then title = title .. "…" end
                                                    table.insert(
                                                        parts,
                                                        string.format("PR#%d:%s", pr_data.number, title)
                                                    )
                                                end
                                            end
                                        end
                                    )

                                    -- Get ahead/behind counts (async)
                                    vim.system(
                                        { "git", "rev-list", "--left-right", "--count", "HEAD...@{u}" },
                                        { cwd = vcs.root },
                                        function(ahead_behind_result)
                                            if ahead_behind_result.code == 0 and ahead_behind_result.stdout then
                                                local output = vim.trim(ahead_behind_result.stdout)
                                                local ahead, behind = output:match("(%d+)%s+(%d+)")
                                                if ahead and behind then
                                                    ahead, behind = tonumber(ahead), tonumber(behind)
                                                    if ahead > 0 then table.insert(parts, "↑" .. ahead) end
                                                    if behind > 0 then table.insert(parts, "↓" .. behind) end
                                                end
                                            end
                                        end
                                    )

                                    -- Get stash count (async)
                                    vim.system({ "git", "stash", "list" }, { cwd = vcs.root }, function(stash_result)
                                        if stash_result.code == 0 and stash_result.stdout then
                                            local stash_count = 0
                                            for _ in stash_result.stdout:gmatch("[^\n]+") do
                                                stash_count = stash_count + 1
                                            end
                                            if stash_count > 0 then table.insert(parts, "󰆓" .. stash_count) end
                                        end

                                        -- Update cache after all async operations complete
                                        vim.schedule(function()
                                            section_cache[cache_key] = {
                                                value = #parts > 0 and table.concat(parts, " ") or "",
                                                timestamp = vim.uv.hrtime() / 1000000,
                                            }
                                            vim.cmd.redrawstatus()
                                        end)
                                    end)
                                end
                            end
                        end)
                    elseif vcs.type == "jj" then
                        -- Get jj change ID (async)
                        vim.system(
                            { "jj", "log", "-r", "@", "--no-graph", "-T", "change_id.short()" },
                            { cwd = vcs.root },
                            function(change_result)
                                if change_result.code == 0 and change_result.stdout then
                                    local change_id = vim.trim(change_result.stdout)
                                    if change_id ~= "" then
                                        table.insert(parts, "jj:" .. change_id)

                                        -- Try to get PR info via gh CLI (async)
                                        vim.system(
                                            { "gh", "pr", "view", "--json", "number,title" },
                                            { cwd = vcs.root },
                                            function(pr_result)
                                                if
                                                    pr_result.code == 0
                                                    and pr_result.stdout
                                                    and pr_result.stdout ~= ""
                                                then
                                                    local ok, pr_data = pcall(vim.json.decode, pr_result.stdout)
                                                    if ok and pr_data.number then
                                                        table.insert(parts, string.format("PR#%d", pr_data.number))
                                                    end
                                                end

                                                -- Update cache after async operations
                                                vim.schedule(function()
                                                    section_cache[cache_key] = {
                                                        value = #parts > 0 and table.concat(parts, " ") or "",
                                                        timestamp = vim.uv.hrtime() / 1000000,
                                                    }
                                                    vim.cmd.redrawstatus()
                                                end)
                                            end
                                        )
                                    end
                                end
                            end
                        )
                    end
                end)

                return stale_value
            end

            return cached.value
        end

        -- VCS section: shows git or jj status (cached)
        local function vcs_section(args)
            return cache_section("vcs:" .. vim.api.nvim_get_current_buf(), function()
                local vcs = project_tools.get_vcs_root(vim.api.nvim_buf_get_name(0))
                if not vcs then return "" end

                if vcs.type == "jj" then
                    -- jj indicator (mini.git doesn't support jj, so just show icon)
                    return "jj"
                else
                    -- git status via mini.statusline
                    return MiniStatusline.section_git(args)
                end
            end)
        end

        -- Lint progress indicator (cached)
        local function lint_section()
            return cache_section("lint:" .. vim.api.nvim_get_current_buf(), function()
                local ok, lint = pcall(require, "lint")
                if not ok then return "" end

                local running = lint.get_running(0)
                if #running == 0 then return "" end

                -- Show running linter count
                return "󱉶 " .. #running
            end)
        end

        -- LSP status with progress tracking
        local lsp_progress_state = {} -- { [client_id] = { title = "...", message = "..." } }

        vim.api.nvim_create_autocmd("LspProgress", {
            callback = function(args)
                local client_id = args.data.client_id
                local result = args.data.result

                -- Guard against nil result
                if not result then return end

                if result.kind == "end" then
                    lsp_progress_state[client_id] = nil
                else
                    lsp_progress_state[client_id] = {
                        title = result.title or "",
                        message = result.message or "",
                        percentage = result.percentage,
                    }
                end

                -- Clear cache to force statusline update
                section_cache["lsp:" .. vim.api.nvim_get_current_buf()] = nil
                vim.cmd.redrawstatus()
            end,
        })

        local function lsp_section()
            return cache_section("lsp:" .. vim.api.nvim_get_current_buf(), function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then return "" end

                -- Check for active progress
                local progress_info = nil
                for _, client in ipairs(clients) do
                    local progress = lsp_progress_state[client.id]
                    if progress then
                        local msg = progress.message ~= "" and progress.message or progress.title
                        progress_info = string.format("󰦖 %s", msg)
                        break
                    end
                end

                if progress_info then return progress_info end

                -- No progress: show attached LSP client names
                local names = {}
                for _, client in ipairs(clients) do
                    table.insert(names, client.name)
                end
                return "󰒋 " .. table.concat(names, ",")
            end)
        end

        MiniStatusline.setup({
            content = {
                active = function()
                    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })

                    -- Terminal buffers: show only mode (minimal statusline, prominent display)
                    if vim.bo.buftype == "terminal" then
                        -- Show full mode name for clarity (NORMAL, INSERT, TERMINAL)
                        local mode_map = {
                            n = "NORMAL",
                            i = "INSERT",
                            t = "TERMINAL",
                            v = "VISUAL",
                            V = "V-LINE",
                            ["\22"] = "V-BLOCK",
                            c = "COMMAND",
                            s = "SELECT",
                        }
                        local current_mode = vim.fn.mode()
                        local mode_display = mode_map[current_mode] or mode

                        return MiniStatusline.combine_groups({
                            { hl = mode_hl, strings = { " " .. mode_display .. " " } },
                            "%=", -- End left alignment
                        })
                    end

                    -- Compute sections (respecting active profile + filetype adjustments)
                    local active_sections = get_active_sections()
                    local git = active_sections.git_status and vcs_section({ trunc_width = 75 }) or ""
                    local branch_meta = active_sections.branch_metadata and branch_metadata_section() or ""
                    local diagnostics = active_sections.diagnostics
                            and MiniStatusline.section_diagnostics({ trunc_width = 75 })
                        or ""
                    local workspace = active_sections.workspace and workspace_section() or ""
                    local lint_info = active_sections.lint and lint_section() or ""
                    local lsp_info = active_sections.lsp and lsp_section() or ""

                    -- Compact filename: just tail, relative to project root when possible (cached)
                    local filename_section = function()
                        return cache_section("filename:" .. vim.api.nvim_get_current_buf(), function()
                            local path = vim.fn.expand("%:p")
                            if path == "" then return "[No Name]" end

                            local root = project_tools.get_current_project_root()
                            local display_path

                            if root and vim.startswith(path, root) then
                                -- Show path relative to project root
                                display_path = path:sub(#root + 2) -- +2 to skip leading slash
                            else
                                -- Fallback to tail + parent dir
                                local filename = vim.fn.expand("%:t")
                                local parent = vim.fn.fnamemodify(vim.fn.expand("%:h"), ":t")
                                display_path = parent ~= "." and parent .. "/" .. filename or filename
                            end

                            -- File status indicators (compact)
                            local modified = vim.bo.modified and "+" or ""
                            local readonly = vim.bo.readonly and "" or ""
                            local status = (modified ~= "" or readonly ~= "") and " [" .. modified .. readonly .. "]"
                                or ""

                            return display_path .. status
                        end)
                    end

                    local filename = filename_section()
                    local location = MiniStatusline.section_location({ trunc_width = 75 })

                    -- Combine devinfo: branch metadata, git status, diagnostics, workspace, lsp, lint
                    local devinfo_parts = {}
                    if branch_meta ~= "" then table.insert(devinfo_parts, branch_meta) end
                    if git ~= "" then table.insert(devinfo_parts, git) end
                    if diagnostics ~= "" then table.insert(devinfo_parts, diagnostics) end
                    if workspace ~= "" then table.insert(devinfo_parts, workspace) end
                    if lsp_info ~= "" then table.insert(devinfo_parts, lsp_info) end
                    if lint_info ~= "" then table.insert(devinfo_parts, lint_info) end
                    local devinfo = table.concat(devinfo_parts, " ")

                    return MiniStatusline.combine_groups({
                        { hl = mode_hl, strings = { mode } },
                        { hl = "MiniStatuslineDevinfo", strings = { devinfo } },
                        "%<", -- Mark truncation point
                        { hl = "MiniStatuslineFilename", strings = { filename } },
                        "%=", -- End left alignment
                        { hl = "MiniStatuslineFileinfo", strings = { location } },
                    })
                end,
            },
            use_icons = true,
            set_vim_settings = true,
        })

        -- Apply nightfly-inspired theme colors
        local colors = require("kyleking.theme").get_colors()

        -- Mode colors (similar to lualine nightfly theme)
        vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = colors.bg0, bg = colors.fg1, bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeInsert", { fg = colors.bg0, bg = colors.green, bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeVisual", { fg = colors.bg0, bg = colors.orange, bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeReplace", { fg = colors.bg0, bg = "#e06c75", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeCommand", { fg = colors.bg0, bg = "#61afef", bold = true })
        vim.api.nvim_set_hl(0, "MiniStatuslineModeOther", { fg = colors.bg0, bg = colors.fg3, bold = true })

        -- Other sections
        vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { fg = colors.fg2, bg = colors.bg2 })
        vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { fg = colors.fg1, bg = colors.bg1 })
        vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { fg = colors.fg2, bg = colors.bg2 })
        vim.api.nvim_set_hl(0, "MiniStatuslineInactive", { fg = colors.fg3, bg = colors.bg1 })

        -- Profile toggle with auto-revert for info-dense
        local K = vim.keymap.set

        local function switch_profile(new_profile)
            if new_profile == current_profile then return end

            current_profile = new_profile
            save_profile_state()

            -- Cancel existing timer if switching away from info-dense
            if info_dense_timer then
                vim.fn.timer_stop(info_dense_timer)
                info_dense_timer = nil
            end

            -- Set auto-revert timer when switching TO info-dense
            if new_profile == "info-dense" then
                info_dense_timer = vim.fn.timer_start(INFO_DENSE_TIMEOUT_MS, function()
                    if current_profile == "info-dense" then
                        current_profile = "compact"
                        save_profile_state()
                        vim.notify("Statusline: auto-reverted to compact (5 min timeout)", vim.log.levels.INFO)
                        vim.cmd.redrawstatus()
                    end
                    info_dense_timer = nil
                end)
                vim.notify("Statusline: info-dense (auto-revert in 5 min)", vim.log.levels.INFO)
            else
                vim.notify("Statusline: compact", vim.log.levels.INFO)
            end

            vim.cmd.redrawstatus()
        end

        local function toggle_profile()
            local new_profile = current_profile == "compact" and "info-dense" or "compact"
            switch_profile(new_profile)
        end

        K("n", "<leader>us", toggle_profile, { desc = "Toggle statusline profile (compact/info-dense)" })

        -- Filetype-specific profile adjustments (auto-apply on buffer enter)
        vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
            group = vim.api.nvim_create_augroup("kyleking_statusline_filetype", { clear = true }),
            callback = function() vim.cmd.redrawstatus() end,
        })

        -- Save profile state on exit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            group = vim.api.nvim_create_augroup("kyleking_statusline_persist", { clear = true }),
            callback = save_profile_state,
        })
    end)
end
