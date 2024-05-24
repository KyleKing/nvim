# nvim

My personal `nvim` configuration. Based on:

- [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
- [AstroNvim/AstroNvim](https://github.com/AstroNvim/AstroNvim) and [AstroNvim/astrocommunity](https://github.com/AstroNvim/astrocommunity)
- [LazyVim/LazyVim](https://github.com/LazyVim/LazyVim)
- [tomodachi94/dotfiles](https://github.com/tomodachi94/dotfiles/tree/main/nvim)

My preference is for opinionated plugins that require minimal configuration.

- Accordingly, I've tried and removed:
    - Bars and lines: [barbar](https://github.com/KyleKing/nvim/commit/186b25c#diff-a08294f302313640d70006877f8111d54587c50a998ceb770b56c704c90fb77a)
    - Buffers: [early-retirement.nvim for auto-closing deleted buffers](https://github.com/KyleKing/nvim/commit/00898cdc3c721d5445a7186cd786fd3c5af7dd9f)
    - Editing Support: [autopairs](https://github.com/KyleKing/nvim/commit/7e106f21d6645454b088b3089c3a3f2d067ffc7c), [nvim-ts-autotag](https://github.com/KyleKing/nvim/commit/460d16f07eb9d2ae49c1f59971948ac3a48f1dde), [cmp-spell, omni, etc.](https://github.com/KyleKing/nvim/commit/f3e92a6586af3dbb3f3735c05e1539a9aeb663c0), [Obsidian](https://github.com/KyleKing/nvim/commit/a60d7317b99ef60fa0677466a778958cf0d950fd)
    - Git: [octo.nvim for Github](https://github.com/KyleKing/nvim/commit/1b3836019ce3943e6f7fcf7d96b728a1f9687c11), [vim-fugitive](https://github.com/KyleKing/nvim/commit/1b3836019ce3943e6f7fcf7d96b728a1f9687c11), [(most of) gitsigns](https://github.com/KyleKing/nvim/commit/0ef02b8422d68d1a266d6c53b28a4f112cd913d9)
    - LSP: [lsp-saga](https://github.com/KyleKing/nvim/commit/da614ec7db07a1e7245744d6f64776c6d04622e9)
    - Marks: [harpoon](https://github.com/KyleKing/nvim/commit/d93f43420229cf43fdc7cab12576d1af1f34b4e6)
    - Motions: [neotab for tabbing out](https://github.com/KyleKing/nvim/commit/61a301f56c11ec01433badb53430368f0cff6ca9)
    - Programming Language Support: [markdown-preview](https://github.com/KyleKing/nvim/commit/3a3b0c667e1b755f26443e5968168db08b460ff3)
    - Session: [auto-session](https://github.com/KyleKing/nvim/commit/7ae6899681355904b83a757f28f014295a0321d8)
    - Utility: [noice](https://github.com/KyleKing/nvim/commit/8a30f4d03c8271756ecd1659e241013e78788834), [structlog](https://github.com/KyleKing/nvim/commit/9e10e13), [dressing](https://github.com/KyleKing/nvim/commit/a58d2e9c71c25ac584cd1581295b8b68d0c516e9)
- I've replaced:
    - [reticle](https://github.com/KyleKing/nvim/commit/3297142) with `colorful-winsep`
    - [indent-blankline](https://github.com/KyleKing/nvim/commit/3e823707087166c1718dc3e0a815a43d472e40a9) with `hlchunk` ([which was later removed](https://github.com/KyleKing/nvim/commit/a9596bb11332a77d74111b4ddd1cdb36b18ba47f))
    - [luacheck](https://github.com/KyleKing/nvim/commit/a76ebc1) with `selene`
    - [buffer-manager](https://github.com/KyleKing/nvim/commit/3bf83abcba6d9e36a0313013ea34d2b3a931a81b) with `telescope`
    - [hlargs](https://github.com/KyleKing/nvim/commit/9ce2a1c) with existing behavior from language LSPs
    - [leap.nvim and alternative motion plugins](https://github.com/KyleKing/nvim/commit/d93f43420229cf43fdc7cab12576d1af1f34b4e6) with `flash.nvim`
    - [quick-scope](https://github.com/KyleKing/nvim/commit/d93f43420229cf43fdc7cab12576d1af1f34b4e6) with `flash.nvim`

## MacOS (and Linux) Install

```sh
NVIM_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
mv $NVIM_CONFIG_DIR ${NVIM_CONFIG_DIR}-backup
mv $HOME/.local/share/nvim $HOME/.local/share/nvim-backup

# FYI: create an alias to manage multiple configurations
# alias nvim-backup='NVIM_APPNAME="${NVIM_CONFIG_DIR}-backup" nvim'

gh repo clone KyleKing/nvim $NVIM_CONFIG_DIR
nvim
```

Any missing CLI tools should be flagged by running `:checkhealth` in `nvim`
