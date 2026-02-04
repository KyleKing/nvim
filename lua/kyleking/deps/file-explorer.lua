local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Note: oil.nvim was evaluated (https://github.com/stevearc/oil.nvim) but mini.files was chosen for:
--  - Column view provides better spatial awareness (parent → current → preview)
--  - Edit-as-buffer semantics identical to oil.nvim (create/delete/rename by editing text)
--  - Native integration with mini.nvim ecosystem (mini.git, mini.pick, consistent UX)
--  - Bookmarks for quick navigation (oil.nvim lacks this)
--  - oil.nvim advantages (SSH, trash) less relevant for primary use case

-- Adapted from: https://github.com/mrjones2014/dotfiles/blob/9914556e4cb346de44d486df90a0410b463998e4/nvim/lua/my/configure/mini_files.lua
later(function()
    local constants = require("kyleking.utils.constants")

    require("mini.files").setup({
        content = {
            filter = function(entry) return not constants.should_ignore(entry.name) end,
        },
        windows = {
            -- Whether to show preview of file/directory under cursor
            preview = true,
            width_preview = 80,
        },
    })

    local K = vim.keymap.set
    K("n", "<leader>e", function()
        local MiniFiles = require("mini.files")
        if vim.bo.ft == "minifiles" then
            MiniFiles.close()
        else
            local file = vim.api.nvim_buf_get_name(0)
            local file_exists = vim.fn.filereadable(file) ~= 0
            MiniFiles.open(file_exists and file or nil)
            MiniFiles.reveal_cwd()
        end
    end, { desc = "Explorer" })

    -- Dynamic bookmark configuration
    local function setup_dynamic_bookmarks()
        local MiniFiles = require("mini.files")
        local fre = require("find-relative-executable")

        -- Always available: home, config, working directory
        MiniFiles.set_bookmark("h", vim.fn.expand("~"), { desc = "Home" })
        MiniFiles.set_bookmark("c", vim.fn.stdpath("config"), { desc = "Nvim config" })
        MiniFiles.set_bookmark("w", vim.fn.getcwd, { desc = "Working directory" })

        -- VCS root (git/jj)
        local vcs = fre.get_vcs_root(vim.api.nvim_buf_get_name(0))
        if vcs then MiniFiles.set_bookmark("v", vcs.root, { desc = "VCS root (" .. vcs.type .. ")" }) end

        -- Common static locations
        local projects_dir = vim.fn.expand("~/projects")
        if vim.fn.isdirectory(projects_dir) == 1 then
            MiniFiles.set_bookmark("p", projects_dir, { desc = "Projects" })
        end

        -- Monorepo detection: common patterns
        if vcs then
            local monorepo_dirs = { "packages", "apps", "services", "libs", "modules", "crates", "workspaces" }
            for _, dir in ipairs(monorepo_dirs) do
                local path = vcs.root .. "/" .. dir
                if vim.fn.isdirectory(path) == 1 then
                    -- Use first letter if not taken, otherwise first available
                    local key = dir:sub(1, 1)
                    local desc = "Monorepo: " .. dir
                    -- Try to set bookmark (mini.files will handle conflicts)
                    pcall(function() MiniFiles.set_bookmark(key, path, { desc = desc }) end)
                end
            end
        end
    end

    -- Setup bookmarks on explorer open
    local minifiles_augroup = vim.api.nvim_create_augroup("ec-mini-files", {})
    vim.api.nvim_create_autocmd("User", {
        group = minifiles_augroup,
        pattern = "MiniFilesExplorerOpen",
        callback = setup_dynamic_bookmarks,
    })

    -- Hidden files toggle
    local show_hidden = true -- Start with hidden files visible
    local function toggle_hidden_files()
        show_hidden = not show_hidden
        local MiniFiles = require("mini.files")
        local new_filter = show_hidden and function(entry) return not constants.should_ignore(entry.name) end
            or function(entry)
                -- Hide dotfiles and ignored files
                return not (entry.name:match("^%.") or constants.should_ignore(entry.name))
            end
        MiniFiles.refresh({ content = { filter = new_filter } })
        vim.notify("Hidden files " .. (show_hidden and "shown" or "hidden"))
    end

    vim.api.nvim_create_autocmd("User", {
        group = minifiles_augroup,
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
            vim.keymap.set("n", "g.", toggle_hidden_files, { buffer = args.data.buf_id, desc = "Toggle hidden files" })
        end,
    })

    -- Git status integration
    -- Source: https://gist.github.com/bassamsdata/eec0a3065152226581f8d4244cce9051
    local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
    local gitStatusCache = {}
    local cacheTimeout = 2000 -- milliseconds

    local function mapSymbols(status)
        local statusMap = {
            [" M"] = { symbol = "•", hlGroup = "MiniDiffSignChange" },
            ["M "] = { symbol = "✹", hlGroup = "MiniDiffSignChange" },
            ["MM"] = { symbol = "≠", hlGroup = "MiniDiffSignChange" },
            ["A "] = { symbol = "+", hlGroup = "MiniDiffSignAdd" },
            ["D "] = { symbol = "-", hlGroup = "MiniDiffSignDelete" },
            ["R "] = { symbol = "→", hlGroup = "MiniDiffSignChange" },
            ["??"] = { symbol = "?", hlGroup = "MiniDiffSignDelete" },
        }
        local result = statusMap[status] or { symbol = " ", hlGroup = "NonText" }
        return result.symbol, result.hlGroup
    end

    local function parseGitStatus(content)
        local gitStatusMap = {}
        for line in content:gmatch("[^\r\n]+") do
            local status, filePath = line:match("^(..)%s+(.*)")
            if status and filePath then
                -- Add status for file and all parent dirs
                local parts = vim.split(filePath, "/", { plain = true })
                local currentPath = ""
                for i, part in ipairs(parts) do
                    currentPath = currentPath == "" and part or currentPath .. "/" .. part
                    if not gitStatusMap[currentPath] or i == #parts then gitStatusMap[currentPath] = status end
                end
            end
        end
        return gitStatusMap
    end

    local function updateMiniWithGit(buf_id, gitStatusMap)
        vim.schedule(function()
            local MiniFiles = require("mini.files")
            local cwd = vim.fs.root(buf_id, ".git")
            if not cwd then return end
            local escapedcwd = vim.fs.normalize(vim.pesc(cwd))

            local nlines = vim.api.nvim_buf_line_count(buf_id)
            for i = 1, nlines do
                local entry = MiniFiles.get_fs_entry(buf_id, i)
                if not entry then break end

                local relativePath = entry.path:gsub("^" .. escapedcwd .. "/", "")
                local status = gitStatusMap[relativePath]

                if status then
                    local symbol, hlGroup = mapSymbols(status)
                    vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
                        sign_text = symbol,
                        sign_hl_group = hlGroup,
                        priority = 2,
                    })
                end
            end
        end)
    end

    local function updateGitStatus(buf_id)
        local cwd = vim.fs.root(buf_id, ".git")
        if not cwd then return end

        local currentTime = os.time()
        if gitStatusCache[cwd] and currentTime - gitStatusCache[cwd].time < cacheTimeout then
            updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
        else
            vim.system({ "git", "status", "--porcelain" }, { text = true, cwd = cwd }, function(result)
                if result.code == 0 then
                    local gitStatusMap = parseGitStatus(result.stdout)
                    gitStatusCache[cwd] = { time = currentTime, statusMap = gitStatusMap }
                    updateMiniWithGit(buf_id, gitStatusMap)
                end
            end)
        end
    end

    vim.api.nvim_create_autocmd("User", {
        group = minifiles_augroup,
        pattern = "MiniFilesExplorerOpen",
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            updateGitStatus(bufnr)
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        group = minifiles_augroup,
        pattern = "MiniFilesBufferUpdate",
        callback = function(args)
            local cwd = vim.fs.root(args.data.buf_id, ".git")
            if cwd and gitStatusCache[cwd] then updateMiniWithGit(args.data.buf_id, gitStatusCache[cwd].statusMap) end
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        group = minifiles_augroup,
        pattern = "MiniFilesExplorerClose",
        callback = function() gitStatusCache = {} end,
    })
end)
