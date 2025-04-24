local MiniDeps = require("mini.deps")
local _add, _now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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

later(function()
    -- Save Mini.Deps snapshot when run from config directory
    if vim.fn.getcwd() == vim.fn.stdpath("config") then
        vim.defer_fn(function() vim.cmd("DepsSnapSave") end, 1000) -- 1 second delay
    end
end)
