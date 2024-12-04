---@class LazyPluginSpec
return {
    "arakkkkk/kanban.nvim",
    -- Only load for matching directory. Based on: https://github.com/LazyVim/LazyVim/discussions/2600#discussioncomment-8572894
    cond = string.match(vim.fn.getcwd(), "/obsidian%-kyleking%-vault") ~= nil,
    event = "UIEnter",
    opts = {},
    keys = {
        { "<leader>kc", "<cmd>KanbanCreate kanban.md<CR>", mode = { "n" }, desc = "Create the default Kanban board" },
        { "<leader>ko", "<cmd>KanbanOpen kanban.md<CR>", mode = { "n" }, desc = "Open the default Kanban board" },
    },
}
