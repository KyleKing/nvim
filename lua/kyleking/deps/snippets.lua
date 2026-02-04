-- Snippet expansion and navigation using mini.snippets
--
-- Provides LSP-integrated snippet support with jump navigation.
-- Keybindings designed to work alongside completion menu.

local add, later = require("mini.deps").add, require("mini.deps").later

later(function()
    add("echasnovski/mini.snippets")

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
            -- Disabled in setup, handled via vim.keymap.set below
            -- This allows better pumvisible() integration
            expand = "",
            jump_next = "",
            jump_prev = "",
            stop = "",
        },
    })

    -- Register LSP snippet source for completion
    -- nvim 0.11+ LSP completion will automatically pick up LSP snippets
    -- when snippet capability is advertised (handled in core/lsp.lua)

    local K = vim.keymap.set

    -- Tab: Expand snippet or jump to next position
    -- Falls through to default Tab behavior when completion menu is open
    K("i", "<Tab>", function()
        if vim.fn.pumvisible() == 1 then return "<Tab>" end
        if snippets.session.get() then
            snippets.session.jump("next")
        else
            -- Try to expand at cursor
            local ok, err = pcall(snippets.expand)
            if not ok then
                -- No snippet at cursor or expansion failed - log unexpected errors
                if err and not err:match("No snippet") then
                    vim.notify("Snippet expansion failed: " .. tostring(err), vim.log.levels.WARN)
                end
                return "<Tab>"
            end
        end
    end, { expr = true, desc = "Expand snippet or jump next" })

    -- Shift-Tab: Jump to previous snippet position
    K("i", "<S-Tab>", function()
        if vim.fn.pumvisible() == 1 then return "<S-Tab>" end
        if snippets.session.get() then
            snippets.session.jump("prev")
        else
            return "<S-Tab>"
        end
    end, { expr = true, desc = "Jump to previous snippet position" })

    -- Ctrl-C: Stop snippet session
    -- Falls through to default Ctrl-C (exit insert mode) after stopping
    K("i", "<C-c>", function()
        if snippets.session.get() then snippets.session.stop() end
        return "<C-c>"
    end, { expr = true, desc = "Stop snippet session" })
end)
