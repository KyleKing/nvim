-- Adapted from: https://github.com/iamdiegow/nvim-lua/blob/6d64d36393936dbb7eb90130b5296f6708c229bc/lua/plugins/parrot.lua#L6
-- Consider prompts like https://github.com/iamdiegow/nvim-lua/blob/6d64d36393936dbb7eb90130b5296f6708c229bc/lua/utils/parrot-prompts.lua
-- Or https://github.com/f/awesome-chatgpt-prompts?tab=readme-ov-file#act-as-a-uxui-developer

---@class LazyPluginSpec
return {
    "frankroeder/parrot.nvim",
    -- lazy = "VeryLazy",
    dependencies = { "ibhagwan/fzf-lua", "nvim-lua/plenary.nvim" },
    opts = {
        providers = {
            ollama = {
                topic = {
                    model = "llama3.2:latest",
                    -- params = { max_tokens = 32 },
                },
                -- params = {
                --     chat = { max_tokens = 1024 },
                --     command = { max_tokens = 1024 },
                -- },
            },
        },
    },
    keys = {
        { "<C-g>c", "<cmd>PrtChatNew<cr>", mode = { "n", "i" }, desc = "New Chat" },
        { "<C-g>c", ":<C-u>'<,'>PrtChatNew<cr>", mode = { "v" }, desc = "Visual Chat New" },
        { "<C-g>f", "<cmd>PrtChatFinder<cr>", mode = { "n", "i" }, desc = "Chat Finder" },
        { "<C-g>r", "<cmd>PrtRewrite<cr>", mode = { "n", "i" }, desc = "Inline Rewrite" },
        { "<C-g>r", ":<C-u>'<,'>PrtRewrite<cr>", mode = { "v" }, desc = "Visual Rewrite" },
        {
            "<C-g>j",
            "<cmd>PrtRetry<cr>",
            mode = { "n" },
            desc = "Retry rewrite/append/prepend command",
        },
        { "<C-g>a", "<cmd>PrtAppend<cr>", mode = { "n", "i" }, desc = "Append" },
        { "<C-g>a", ":<C-u>'<,'>PrtAppend<cr>", mode = { "v" }, desc = "Visual Append" },
        { "<C-g>o", "<cmd>PrtPrepend<cr>", mode = { "n", "i" }, desc = "Prepend" },
        { "<C-g>o", ":<C-u>'<,'>PrtPrepend<cr>", mode = { "v" }, desc = "Visual Prepend" },
        { "<C-g>e", ":<C-u>'<,'>PrtNew<cr>", mode = { "v" }, desc = "Visual New" },
        { "<C-g>s", "<cmd>PrtStop<cr>", mode = { "n", "i", "v", "x" }, desc = "Stop" },
        {
            "<C-g>i",
            ":<C-u>'<,'>PrtComplete<cr>",
            mode = { "n", "i", "v", "x" },
            desc = "Complete visual selection",
        },
        { "<C-g>x", "<cmd>PrtContext<cr>", mode = { "n" }, desc = "Open context file" },
        { "<C-g>n", "<cmd>PrtModel<cr>", mode = { "n" }, desc = "Select model" },
        { "<C-g>p", "<cmd>PrtProvider<cr>", mode = { "n" }, desc = "Select provider" },
        { "<C-g>q", "<cmd>PrtAsk<cr>", mode = { "n" }, desc = "Ask a question" },

        { "<C-g>tv", "<cmd>PrtChatToggle vsplit<CR>", desc = "Toggle Chat vsplit(Parrot)" },
        { "<C-g>ts", "<cmd>PrtChatToggle split<CR>", desc = "Toggle Chat split(Parrot)" },
        { "<C-g><C-g>", "<cmd>PrtChatToggle popup<CR>", desc = "Toggle Chat popup(Parrot)" },
    },
}
