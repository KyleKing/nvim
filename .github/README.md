# nvim

My personal `nvim` configuration. Based on:

- [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
- [AstroNvim/AstroNvim](https://github.com/AstroNvim/AstroNvim) and [AstroNvim/astrocommunity](https://github.com/AstroNvim/astrocommunity)
- [LazyVim/LazyVim](https://github.com/LazyVim/LazyVim)
- [tomodachi94/dotfiles](https://github.com/tomodachi94/dotfiles/tree/main/nvim)

My preference is for opinionated plugins that require minimal configuration.

- Accordingly, I've tried and removed:
    - Bars and lines: [barbar](https://github.com/KyleKing/nvim/commit/186b25c#diff-a08294f302313640d70006877f8111d54587c50a998ceb770b56c704c90fb77a)
    - Editing Support: [autopairs](https://github.com/KyleKing/nvim/commit/7e106f21d6645454b088b3089c3a3f2d067ffc7c), [cmp-spell, omni, etc.](https://github.com/KyleKing/nvim/commit/f3e92a6586af3dbb3f3735c05e1539a9aeb663c0)
    - LSP: [lsp-saga](https://github.com/KyleKing/nvim/commit/da614ec7db07a1e7245744d6f64776c6d04622e9)
    - Utility: [noice](https://github.com/KyleKing/nvim/commit/8a30f4d03c8271756ecd1659e241013e78788834), [structlog](https://github.com/KyleKing/nvim/commit/9e10e13)
- I've replaced [reticle](https://github.com/KyleKing/nvim/commit/3297142) with `colorful-winsep`, [indent-blankline](https://github.com/KyleKing/nvim/commit/3e823707087166c1718dc3e0a815a43d472e40a9) with `hlchunk`, [luacheck](https://github.com/KyleKing/nvim/commit/a76ebc1) with `selene`, and [hlargs](https://github.com/KyleKing/nvim/commit/9ce2a1c) with the behavior of my chosen color scheme

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
