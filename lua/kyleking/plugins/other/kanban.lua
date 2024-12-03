---@class LazyPluginSpec
return {
    "arakkkkk/kanban.nvim",
    -- Only load for a specific directory. Based on: https://github.com/LazyVim/LazyVim/discussions/2600#discussioncomment-8572894
    cond = vim.fn.getcwd() == vim.fn.expand("~/Developer/kyleking/task_vault"),
    opts = {},
    keys = {
        { "<leader>kc", "<cmd>KanbanCreate kanban.md<CR>", mode = { "n" }, desc = "Create the default Kanban board" },
        { "<leader>ko", "<cmd>KanbanOpen kanban.md<CR>", mode = { "n" }, desc = "Open the default Kanban board" },
    },
}
