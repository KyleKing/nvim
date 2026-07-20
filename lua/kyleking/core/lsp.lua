-- :h lsp-config

-- Track auto-completion mode per buffer (false = manual, true = auto)
local completion_autotrigger = {}

-- Toggle completion mode between manual and auto-trigger
local function toggle_completion_mode(bufnr)
    local current_mode = completion_autotrigger[bufnr] or false
    local new_mode = not current_mode
    completion_autotrigger[bufnr] = new_mode

    -- Re-enable completion with new autotrigger setting
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = new_mode })
        end
    end

    local mode_name = new_mode and "auto-trigger" or "manual trigger"
    vim.notify(string.format("Completion mode: %s", mode_name), vim.log.levels.INFO)
end

-- Enable built-in LSP completion (nvim 0.11+)
-- Adapted from: https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            -- Enable completion with manual trigger by default (toggle with <leader>ca)
            local autotrigger = completion_autotrigger[ev.buf] or false
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = autotrigger })

            -- Keymaps for completion (buffer-local)
            local opts = { buffer = ev.buf, silent = true }

            -- Trigger completion manually (<C-x><C-o> for 0.11, native trigger for 0.12+)
            local trigger = vim.lsp.completion.trigger or function() vim.api.nvim_feedkeys("\24\15", "n", false) end
            vim.keymap.set("i", "<C-Space>", trigger, opts)

            -- Menu navigation (<C-j>/<C-k>), acceptance (<C-CR>), and abort (<CR>) are
            -- global Insert-mode multistep maps in deps/keymap.lua (mini.keymap).

            -- Toggle between manual and auto-trigger completion
            vim.keymap.set("n", "<leader>ca", function() toggle_completion_mode(ev.buf) end, {
                buffer = ev.buf,
                silent = true,
                desc = "Toggle completion mode (manual/auto)",
            })

            -- Signature help (both normal and insert mode)
            if client:supports_method("textDocument/signatureHelp") then
                vim.keymap.set(
                    { "n", "i" },
                    "<leader>ks",
                    vim.lsp.buf.signature_help,
                    vim.tbl_extend("force", opts, { desc = "Show signature help" })
                )
            end
        end
    end,
})

-- Configurations are loaded from `neovim/nvim-lspconfig`
