-- Snippet expansion and navigation using mini.snippets
--
-- Provides LSP-integrated snippet support with jump navigation.
-- Keybindings designed to work alongside completion menu.

local later = require("mini.deps").later

later(function()
    -- mini.snippets ships in the mini.nvim bundle; no separate add() needed
    local snippets = require("mini.snippets")

    snippets.setup({
        snippets = {
            -- Start with LSP-provided snippets only
            -- Custom snippets can be added here later
        },
        expand = {
            -- Use default jump indicators (default: │)
        },
        mappings = {
            -- Disabled here: expand/jump are driven by mini.keymap (deps/keymap.lua)
            -- and stop by <C-c> below
            expand = "",
            jump_next = "",
            jump_prev = "",
            stop = "",
        },
    })

    -- Register LSP snippet source for completion
    -- nvim 0.11+ LSP completion will automatically pick up LSP snippets
    -- when snippet capability is advertised (handled in core/lsp.lua)

    -- Tab/S-Tab expand and jump snippets via mini.keymap multistep (see deps/keymap.lua).

    -- Ctrl-C: Stop snippet session
    -- Falls through to default Ctrl-C (exit insert mode) after stopping
    vim.keymap.set("i", "<C-c>", function()
        if snippets.session.get() then snippets.session.stop() end
        return "<C-c>"
    end, { expr = true, desc = "Stop snippet session" })
end)
