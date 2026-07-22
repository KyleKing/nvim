-- Local plugin checkouts under ~/Developer/kyleking, installed via file:// so
-- vim.pack tracks them in the lockfile like any other plugin. Local edits only
-- take effect after committing in the source repo and running vim.pack.update().
local pack = require("kyleking.pack")
local deps_utils = require("kyleking.deps_utils")
local add, later = pack.add, deps_utils.maybe_later

later(function()
    add({ source = "file:///Users/kyleking/Developer/kyleking/spaghetti-comb.nvim" })
    require("spaghetti-comb").setup({})

    local K = vim.keymap.set
    K("n", "<leader>nb", "<cmd>SpaghettiCombBack<cr>", { desc = "Navigate back in trail" })
    K("n", "<leader>nf", "<cmd>SpaghettiCombForward<cr>", { desc = "Navigate forward in trail" })
    K("n", "<leader>nh", "<cmd>SpaghettiCombHistory<cr>", { desc = "Navigation history picker" })
    K("n", "<leader>nm", "<cmd>SpaghettiCombBookmarkToggle<cr>", { desc = "Toggle bookmark here" })
    K("n", "<leader>nM", "<cmd>SpaghettiCombBookmarks<cr>", { desc = "Bookmark picker" })
    K("n", "<leader>nn", "<cmd>SpaghettiCombBreadcrumbs<cr>", { desc = "Toggle breadcrumb bar" })
    K("n", "<leader>nt", "<cmd>SpaghettiCombTree<cr>", { desc = "Toggle navigation tree" })
end)
