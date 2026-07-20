local deps_utils = require("kyleking.deps_utils")
local later = deps_utils.maybe_later

-- Smart Insert-mode keys via mini.keymap multistep. Consolidates the completion-menu
-- navigation (previously hand-rolled with pumvisible() checks in core/lsp.lua) and the
-- mini.snippets expand/jump logic (previously in deps/snippets.lua). Each step runs only
-- when its condition holds; otherwise the mapping falls back to the literal key.
later(function()
    local map_multistep = require("mini.keymap").map_multistep

    -- Tab/S-Tab expand or jump mini.snippets. Menu navigation is intentionally on
    -- <C-j>/<C-k>, so the pmenu steps are omitted here (Tab stays literal over the menu).
    map_multistep("i", "<Tab>", { "minisnippets_next", "minisnippets_expand" })
    map_multistep("i", "<S-Tab>", { "minisnippets_prev" })

    -- Completion menu navigation and explicit acceptance on <C-CR>.
    map_multistep("i", "<C-j>", { "pmenu_next" })
    map_multistep("i", "<C-k>", { "pmenu_prev" })
    map_multistep("i", "<C-CR>", { "pmenu_accept" })

    -- <CR> aborts an open completion menu and inserts a newline; acceptance is <C-CR>.
    -- Buffer-local <CR> maps (e.g. list editing) still take precedence where set.
    local abort_completion = {
        condition = function() return vim.fn.pumvisible() == 1 end,
        action = function() return "<C-e><CR>" end,
    }
    map_multistep("i", "<CR>", { abort_completion })
end)
