-- FIXME: Add desc for each command that is kept
local opts = { noremap = true, silent = true, desc = "placeholder!" }

return {
  "romgrk/barbar.nvim",
  lazy = false,
  dependencies = {
    "lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
    "nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
  },
  init = function() vim.g.barbar_auto_setup = false end,
  opts = {},
  keys = {
    -- TODO: De-dupe with nap and choose more consistent keybinds

    -- Move to previous/next
    { "<A-,>", "<Cmd>BufferPrevious<CR>", opts },
    { "<A-.>", "<Cmd>BufferNext<CR>", opts },
    -- Re-order to previous/next
    { "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts },
    { "<A->>", "<Cmd>BufferMoveNext<CR>", opts },
    -- Goto buffer in position...
    { "<A-1>", "<Cmd>BufferGoto 1<CR>", opts },
    { "<A-2>", "<Cmd>BufferGoto 2<CR>", opts },
    { "<A-3>", "<Cmd>BufferGoto 3<CR>", opts },
    { "<A-4>", "<Cmd>BufferGoto 4<CR>", opts },
    { "<A-5>", "<Cmd>BufferGoto 5<CR>", opts },
    { "<A-6>", "<Cmd>BufferGoto 6<CR>", opts },
    { "<A-7>", "<Cmd>BufferGoto 7<CR>", opts },
    { "<A-8>", "<Cmd>BufferGoto 8<CR>", opts },
    { "<A-9>", "<Cmd>BufferGoto 9<CR>", opts },
    { "<A-0>", "<Cmd>BufferLast<CR>", opts },
    -- Pin/unpin buffer
    { "<A-p>", "<Cmd>BufferPin<CR>", opts },
    -- Close buffer
    { "<A-c>", "<Cmd>BufferClose<CR>", opts },
    -- Wipeout buffer
    --                 :BufferWipeout
    -- Close commands
    --                 :BufferCloseAllButCurrent
    --                 :BufferCloseAllButPinned
    --                 :BufferCloseAllButCurrentOrPinned
    --                 :BufferCloseBuffersLeft
    --                 :BufferCloseBuffersRight
    -- Magic buffer-picking mode
    { "<C-p>", "<Cmd>BufferPick<CR>", opts },
    -- Sort automatically by...
    { "<Space>bb", "<Cmd>BufferOrderByBufferNumber<CR>", opts },
    { "<Space>bd", "<Cmd>BufferOrderByDirectory<CR>", opts },
    { "<Space>bl", "<Cmd>BufferOrderByLanguage<CR>", opts },
    { "<Space>bw", "<Cmd>BufferOrderByWindowNumber<CR>", opts },
  },
}
