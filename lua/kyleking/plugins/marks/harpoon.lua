-- From: https://github.com/ThePrimeagen/harpoon/pull/422#issuecomment-1872992179
return {
    "ThePrimeagen/harpoon",
    enabled = false, -- PLANNED: investigate
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "UIEnter",
    opts = {},
    keys = {
        {
            "<leader>ha",
            function() require('harpoon.mark').add_file() end,
            desc = "Mark file with Harpoon",
        },
        {
            "<leader>he",
            function() require('harpoon.ui').toggle_quick_menu(require('harpoon'):list()) end,
            desc = "Toggle Harpoon menu",
        },
        {
            "<leader>h1",
            function() require('harpoon.ui').nav_file(1) end,
            desc = "Harpoon mark 1",
        },
        {
            "<leader>h2",
            function() require('harpoon.ui').nav_file(2) end,
            desc = "Harpoon mark 2",
        },
        {
            "<leader>h3",
            function() require('harpoon.ui').nav_file(3) end,
            desc = "Harpoon mark 3",
        },
        {
            "<leader>h4",
            function() require('harpoon.ui').nav_file(4) end,
            desc = "Harpoon mark 4",
        },
        {
            "<leader>hp",
            function() require("harpoon"):list():prev() end,
            desc = "Toggle Previous Buffer",
        },
        {
            "<leader>hn",
            function() require("harpoon"):list():next() end,
            desc = "Toggle Next Buffer",
        },
    },
}
