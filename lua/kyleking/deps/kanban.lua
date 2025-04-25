local MiniDeps = require("mini.deps")
local add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(function()
    -- Only load for matching directory. Based on: https://github.com/LazyVim/LazyVim/discussions/2600#discussioncomment-8572894
    if string.match(vim.fn.getcwd(), "/obsidian%-kyleking%-vault") ~= nil then
        add("arakkkkk/kanban.nvim")
        require("kanban").setup()

        local K = vim.keybind.set
        K("n", "<leader>kO", "<cmd>KanbanCreate kanban.md<CR>", { desc = "Initialize default Kanban board" })
        K("n", "<leader>kc", "<cmd>KanbanClose<CR>", { desc = "Close the Kanban Board" })
        K("n", "<leader>ko", "<cmd>KanbanOpen kanban.md<CR>", { desc = "Open the default Kanban board" })
        K("n", "<leader>ks", "<cmd>KanbanSave<CR>", { desc = "Save the Kanban Board" })
    end
end)
