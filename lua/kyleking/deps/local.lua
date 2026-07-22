-- Local plugin checkouts under ~/Developer/kyleking, installed via file:// so
-- vim.pack tracks them in the lockfile like any other plugin. Local edits only
-- take effect after committing in the source repo and running vim.pack.update().
local pack = require("kyleking.pack")
local deps_utils = require("kyleking.deps_utils")
local add, later = pack.add, deps_utils.maybe_later

-- file:// sources are fragile: if the source repo doesn't exist yet when nvim first
-- runs add(), or if a clone/checkout gets interrupted, vim.pack can end up with the
-- plugin "installed" in the lockfile but an empty or partial working tree. require()
-- then fails deep inside the plugin with a generic "module not found", which gives no
-- hint that the local checkout (not the plugin itself) is the problem. Checking for the
-- entry module before add() catches both cases with an actionable message instead.
local function add_local(repo, module_name, opts)
    local path = "/Users/kyleking/Developer/kyleking/" .. repo
    if vim.fn.filereadable(path .. "/lua/" .. module_name .. "/init.lua") ~= 1 then
        vim.notify(
            ("local plugin %s: no lua/%s/init.lua under %s (missing source repo or a broken vim.pack checkout -- "):format(
                repo,
                module_name,
                path
            )
                .. "delete the installed copy under site/pack/*/opt/"
                .. repo
                .. " and reopen nvim to reinstall)",
            vim.log.levels.WARN
        )
        return false
    end
    add({ source = "file://" .. path })
    local ok, err = pcall(require(module_name).setup, opts)
    if not ok then
        vim.notify(
            ("local plugin %s: setup() failed after install -- %s"):format(repo, tostring(err)),
            vim.log.levels.ERROR
        )
        return false
    end
    return true
end

later(function()
    if not add_local("codanna.nvim", "codanna", { preferred_picker = "mini" }) then return end

    local K = vim.keymap.set
    K("n", "<leader>sC", "<cmd>CodannaCalls<cr>", { desc = "Codanna outgoing calls" })
    K("n", "<leader>sc", "<cmd>CodannaCallers<cr>", { desc = "Codanna callers" })
    K("n", "<leader>sd", "<cmd>CodannaDocuments<cr>", { desc = "Codanna documents" })
    K("n", "<leader>si", "<cmd>CodannaImpact<cr>", { desc = "Codanna impact analysis" })
    K("n", "<leader>ss", "<cmd>CodannaSearch<cr>", { desc = "Codanna semantic search" })
    K("n", "<leader>sy", "<cmd>CodannaSymbols<cr>", { desc = "Codanna symbols" })
end)

later(function()
    if not add_local("spaghetti-comb.nvim", "spaghetti-comb", {}) then return end

    local K = vim.keymap.set
    K("n", "<leader>nb", "<cmd>SpaghettiCombBack<cr>", { desc = "Navigate back in trail" })
    K("n", "<leader>nf", "<cmd>SpaghettiCombForward<cr>", { desc = "Navigate forward in trail" })
    K("n", "<leader>nh", "<cmd>SpaghettiCombHistory<cr>", { desc = "Navigation history picker" })
    K("n", "<leader>nm", "<cmd>SpaghettiCombBookmarkToggle<cr>", { desc = "Toggle bookmark here" })
    K("n", "<leader>nM", "<cmd>SpaghettiCombBookmarks<cr>", { desc = "Bookmark picker" })
    K("n", "<leader>nn", "<cmd>SpaghettiCombBreadcrumbs<cr>", { desc = "Toggle breadcrumb bar" })
    K("n", "<leader>nt", "<cmd>SpaghettiCombTree<cr>", { desc = "Toggle navigation tree" })
end)
