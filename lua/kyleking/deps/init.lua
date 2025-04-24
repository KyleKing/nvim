-- local MiniDeps = require("mini.deps")
-- local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- now(function()
--     require("mini.notify").setup()
--     vim.notify = require("mini.notify").make_notify()
-- end)
-- now(function() require("mini.icons").setup() end)
-- now(function() require("mini.tabline").setup() end)
-- now(function() require("mini.statusline").setup() end)

-- later(function() require("mini.ai").setup() end)
-- later(function() require("mini.comment").setup() end)
-- later(function() require("mini.pick").setup() end)
-- later(function() require("mini.surround").setup() end)

require("kyleking.deps.lsp")

-- later(function()
--     add({
--         source = "nvim-treesitter/nvim-treesitter",
--         hooks = { post_checkout = function() vim.cmd("TSUpdate") end },
--     })
--     require("nvim-treesitter.configs").setup({
--         ensure_installed = { "lua", "vimdoc" },
--         highlight = { enable = true },
--     })
-- end)
