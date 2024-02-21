-- See `:help vim.opt`
--  Or for `vim.opt.clipboard`, see `:help 'clipboard'` for documentation

vim.opt.mousescroll = "ver:1,hor:0" -- prevent horizontal scroll (https://vi.stackexchange.com/a/42209)
vim.opt.backspace:append({ "nostop" }) -- don't stop backspace at insert
vim.opt.breakindent = true -- wrap indent to match  line start
vim.opt.clipboard = "unnamedplus" -- connection to the system clipboard
vim.opt.cmdheight = 0 -- hide command line unless needed
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- Options for insert mode completion
vim.opt.copyindent = true -- copy the previous indentation on auto-indenting
vim.opt.cursorline = true -- highlight the text line of the cursor
vim.opt.diffopt:append({ "algorithm:histogram", "linematch:60" }) -- enable linematch diff algorithm
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
vim.opt.pumheight = 15 -- height of the pop up menu
vim.opt.relativenumber = true -- show relative numberline
vim.opt.shortmess:append({ s = true, I = true }) -- disable search count wrap and startup messages
vim.opt.showmode = false -- disable showing modes in command line
vim.opt.showtabline = 1 -- (default) show tabline only if more than one tab
vim.opt.signcolumn = "yes" -- always show the sign column
vim.opt.smartcase = true -- case sensitive searching when \C or a capital in search
vim.opt.splitbelow = true -- splitting a new window below the current one
vim.opt.splitright = true -- splitting a new window at the right of the current one
vim.opt.termguicolors = true -- enable 24-bit RGB color in the TUI
vim.opt.timeoutlen = 500 -- shorten key timeout length a little bit for which-key
vim.opt.title = true -- set terminal title to the filename and path
vim.opt.undofile = true -- enable persistent undo
vim.opt.updatetime = 250 -- length of time to wait before triggering the plugin
vim.opt.viewoptions:remove("curdir") -- disable saving current directory with views
vim.opt.virtualedit = "block" -- allow going past end of line in visual block mode
-- vim.opt.wrap = false -- disable wrapping of lines longer than the width of window
vim.opt.writebackup = false -- disable making a backup before overwriting a file
-- vim.opt.colorcolumn = "80,120" -- highlighted screen columns (switched to smartcolumn plugin instead)
vim.opt.scrolloff = 16 -- Number of screen lines to keep above and below the cursor
vim.opt.wildmode = "full:lastused" -- complete the first full match immediately <https://stackoverflow.com/a/76471693/3219667>
-- vim.opt.spelllang = "en_us" -- Use the US dictionary (and any associated custom dictionaries) -- *Update*: set by plugin dirty-talk
vim.opt.spell = true -- Always on spell checking

-- Default indentation (unless overridden by editorconfig)
vim.opt.expandtab = true -- enable the use of space in tab
vim.opt.shiftwidth = 4 -- number of space inserted for indentation
vim.opt.tabstop = 4 -- number of space in a tab

-- Custom filetypes
vim.filetype.add({
    extension = {
        conf = "conf",
        mdx = "markdown",
    },
    pattern = {
        [".*%.env.*"] = "sh",
        ["ignore$"] = "conf",
    },
    filename = {},
})
