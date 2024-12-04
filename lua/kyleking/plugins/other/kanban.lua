---@class LazyPluginSpec
return {
    "arakkkkk/kanban.nvim",
    -- Only load for matching directory. Based on: https://github.com/LazyVim/LazyVim/discussions/2600#discussioncomment-8572894
    cond = string.match(vim.fn.getcwd(), "/obsidian%-kyleking%-vault") ~= nil,
    event = "UIEnter",
    opts = {},
    keys = {
        { "<leader>kO", "<cmd>KanbanCreate kanban.md<CR>", mode = { "n" }, desc = "Initialize default Kanban board" },
        { "<leader>kc", "<cmd>KanbanClose<CR>", mode = { "n" }, desc = "Close the Kanban Board" },
        { "<leader>ko", "<cmd>KanbanOpen kanban.md<CR>", mode = { "n" }, desc = "Open the default Kanban board" },
        { "<leader>ks", "<cmd>KanbanSave<CR>", mode = { "n" }, desc = "Save the Kanban Board" },
    },
}
