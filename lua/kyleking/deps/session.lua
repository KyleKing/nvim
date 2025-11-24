local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- mini.sessions - Session management
later(function()
    local sessions = require("mini.sessions")
    sessions.setup({
        -- Whether to read latest session if Neovim opened without file arguments
        autoread = false,
        -- Whether to write current session before quitting Neovim
        autowrite = true,
        -- Directory where global sessions are stored
        directory = vim.fn.stdpath('data') .. '/sessions',
        -- File for local session (relative to current working directory)
        file = '.nvim-session',
        -- Whether to force possibly harmful actions (meaning depends on function)
        force = { read = false, write = true, delete = false },
        -- Hook functions for different stages of session operations
        hooks = {
            -- Before session read
            pre = { read = nil, write = nil, delete = nil },
            -- After session read
            post = { read = nil, write = nil, delete = nil },
        },
        -- Whether to print session path after action
        verbose = { read = false, write = true, delete = true },
    })

    -- Keymaps for session management
    local K = vim.keymap.set

    -- Session operations
    K("n", "<leader>Ss", function()
        -- Save session with name prompt
        local name = vim.fn.input("Session name: ")
        if name ~= "" then
            sessions.write(name)
        end
    end, { desc = "Save session" })

    K("n", "<leader>Sr", function()
        -- Read session with picker
        sessions.select('read')
    end, { desc = "Read session" })

    K("n", "<leader>Sd", function()
        -- Delete session with picker
        sessions.select('delete')
    end, { desc = "Delete session" })

    K("n", "<leader>Sl", function()
        -- Read latest session
        sessions.read(sessions.detected, { force = false })
    end, { desc = "Load latest session" })

    K("n", "<leader>Sw", function()
        -- Write to current session
        sessions.write(nil, { force = true })
    end, { desc = "Write current session" })

    K("n", "<leader>SL", function()
        -- Read local session (from .nvim-session in cwd)
        local local_session = vim.fn.getcwd() .. '/.nvim-session'
        if vim.fn.filereadable(local_session) == 1 then
            vim.cmd('source ' .. local_session)
        else
            vim.notify("No local session found", vim.log.levels.WARN)
        end
    end, { desc = "Load local session" })

    K("n", "<leader>SW", function()
        -- Write local session (to .nvim-session in cwd)
        local local_session = vim.fn.getcwd() .. '/.nvim-session'
        vim.cmd('mksession! ' .. local_session)
        vim.notify("Local session saved to " .. local_session, vim.log.levels.INFO)
    end, { desc = "Write local session" })

    -- Autocommand to prompt for session save on exit
    vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
            -- Only auto-save if there's a current session
            if sessions.detected then
                sessions.write(nil, { force = true })
            end
        end,
    })
end)
