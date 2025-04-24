local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

--- A table to manage ToggleTerm terminals created by the user, indexed by the command run and then the instance number
---@type table<string,table<integer,table>>
local user_terminals = {}

--- Toggle a user terminal if it exists, if not then create a new one and save it
---@param opts string|table A terminal command string or a table of options for Terminal:new() (Check toggleterm.nvim documentation for table format)
local function toggle_term_cmd(opts)
    local terms = user_terminals
    -- if a command string is provided, create a basic table for Terminal:new() options
    if type(opts) == "string" then opts = { cmd = opts, hidden = true } end
    -- if terminal doesn't exist yet, create it
    if not terms[opts.cmd] then terms[opts.cmd] = {} end
    local num = vim.v.count > 0 and vim.v.count or 1
    if not terms[opts.cmd][num] then
        if not opts.count then opts.count = vim.tbl_count(terms) * 100 + num end
        if not opts.on_exit then opts.on_exit = function() terms[opts.cmd][num] = nil end end
        terms[opts.cmd][num] = require("toggleterm.terminal").Terminal:new(opts)
    end
    -- toggle the terminal
    terms[opts.cmd][num]:toggle()
end

---@class LazyPluginSpec
later(function()
    add("akinsho/toggleterm.nvim")

    require("toggleterm").setup({
        shading_factor = 4,
        direction = "float",
    })

    local K = vim.keymap.set
    K("n", "<leader>gg", function()
        local worktree = require("kyleking.utils.fs_utils").file_worktree()
        local flags = worktree and ("--work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir) or ""
        toggle_term_cmd("lazygit " .. flags)
    end, { desc = "ToggleTerm lazygit" })
    K("n", "<leader>gj", function() toggle_term_cmd("lazyjj") end, { desc = "ToggleTerm lazyjj" })
    K("n", "<leader>td", function() toggle_term_cmd("lazydocker") end, { desc = "ToggleTerm 'lazydocker'" })
    K("n", "<leader>tf", "<Cmd>ToggleTerm direction=float<CR>", { desc = "ToggleTerm float" })
    K("n", "<leader>th", "<Cmd>ToggleTerm size=15 direction=horizontal<CR>", { desc = "ToggleTerm horizontal split" })
    K("n", "<leader>tv", "<Cmd>ToggleTerm size=80 direction=vertical<CR>", { desc = "ToggleTerm vertical split" })
    K({ "n", "t" }, "<C-'>", "<Cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })
end)
