-- From: https://github.com/ThePrimeagen/harpoon/pull/422#issuecomment-1872992179
return {
   "ThePrimeagen/harpoon",
   enabled = false, -- PLANNED: investigate
   branch = "harpoon2",
   dependencies = { "nvim-lua/plenary.nvim" },
   lazy = false,
   init = function()
      -- PLANNED: refactor to use standard Lazy opts/keys
      local harpoon = require("harpoon")

      -- REQUIRED
      harpoon:setup()
      -- REQUIRED

      vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

      vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end)

      -- -- Toggle previous & next buffers stored within Harpoon list
      -- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
      -- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
   end,
}
