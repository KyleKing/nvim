# nvim

My personal `nvim` configuration. Based on:

- [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
- [AstroNvim/AstroNvim](https://github.com/AstroNvim/AstroNvim) and [AstroNvim/astrocommunity](https://github.com/AstroNvim/astrocommunity)
- [LazyVim/LazyVim](https://github.com/LazyVim/LazyVim)

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
