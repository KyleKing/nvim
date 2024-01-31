-- See `:help vim.opt`
--  Or for `vim.opt.clipboard`, see `:help 'clipboard'` for documentation

vim.opt.mousescroll = "ver:1,hor:0" -- prevent horizontal scroll (https://vi.stackexchange.com/a/42209)
vim.opt.backspace:append { "nostop" } -- don't stop backspace at insert
vim.opt.breakindent = true -- wrap indent to match  line start
vim.opt.clipboard = "unnamedplus" -- connection to the system clipboard
vim.opt.cmdheight = 0 -- hide command line unless needed
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- Options for insert mode completion
vim.opt.copyindent = true -- copy the previous indentation on autoindenting
vim.opt.cursorline = true -- highlight the text line of the cursor
vim.opt.diffopt:append { "algorithm:histogram", "linematch:60" } -- enable linematch diff algorithm
vim.opt.expandtab = true -- enable the use of space in tab
vim.opt.fileencoding = "utf-8" -- file content encoding for the buffer
vim.opt.fillchars = { eob = " " } -- disable `~` on nonexistent lines
vim.opt.foldlevelstart = 99 -- start with all code unfolded
vim.opt.history = 100 -- number of commands to remember in a history table
vim.opt.ignorecase = true -- case insensitive searching
vim.opt.infercase = true -- infer cases in keyword completion
vim.opt.laststatus = 3 -- global statusline
vim.opt.linebreak = true -- wrap lines at 'breakat'
vim.opt.mouse = "a" -- enable mouse support
vim.opt.number = true -- show numberline
vim.opt.preserveindent = true -- preserve indent structure as much as possible
vim.opt.pumheight = 10 -- height of the pop up menu
vim.opt.relativenumber = true -- show relative numberline
vim.opt.shiftwidth = 2 -- number of space inserted for indentation
vim.opt.shortmess:append { s = true, I = true } -- disable search count wrap and startup messages
vim.opt.showmode = false -- disable showing modes in command line
vim.opt.showtabline = 2 -- always display tabline
vim.opt.signcolumn = "yes" -- always show the sign column
vim.opt.smartcase = true -- case sensitive searching when \C or a capital in search
vim.opt.splitbelow = true -- splitting a new window below the current one
vim.opt.splitright = true -- splitting a new window at the right of the current one
vim.opt.tabstop = 2 -- number of space in a tab
vim.opt.termguicolors = true -- enable 24-bit RGB color in the TUI
vim.opt.timeoutlen = 300 -- shorten key timeout length a little bit for which-key
vim.opt.title = true -- set terminal title to the filename and path
vim.opt.undofile = true -- enable persistent undo
vim.opt.updatetime = 300 -- length of time to wait before triggering the plugin
vim.opt.viewoptions:remove "curdir" -- disable saving current directory with views
vim.opt.virtualedit = "block" -- allow going past end of line in visual block mode
-- vim.opt.wrap = false -- disable wrapping of lines longer than the width of window
vim.opt.writebackup = false -- disable making a backup before overwriting a file

-- vim.opt.colorcolumn = "80,120" -- PLANNED: Find a way to add these

-- PLANNED: consider additional options
-- -- Set completeopt to have a better completion experience
-- vim.opt.completeopt = 'menuone,noselect'
