-- From: https://youtu.be/5ht8NYkU9wQ?si=dFyWjihXcf-9YDk2
return {
    "epwalsh/obsidian.nvim",
    enabled = false,
    event = {
        "BufReadPre " .. vim.fn.expand("~") .. "/MyDocuments/Obsidian-Vaults/obsidian-kyleking-vault/**.md",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        workspaces = {
            {
                name = "obsidian-kyleking-vault",
                path = vim.fn.expand("~") .. "/MyDocuments/Obsidian-Vaults/obsidian-kyleking-vault/**.md",
            },
        },
        completion = {
            nvim_cmp = true,
            min_chars = 2, -- Trigger completion at 2 chars.
        },
    },
}
