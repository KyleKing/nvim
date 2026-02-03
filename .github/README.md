# nvim

My personal `nvim` configuration. Based on:

- [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
- [AstroNvim/AstroNvim](https://github.com/AstroNvim/AstroNvim) and [AstroNvim/astrocommunity](https://github.com/AstroNvim/astrocommunity)
- [LazyVim/LazyVim](https://github.com/LazyVim/LazyVim)
- [tomodachi94/dotfiles](https://github.com/tomodachi94/dotfiles/tree/8dc76a30ae9ddcdb4c9b277209408cd2201b63d3/home/common/nvim)
- [NativeVim](https://github.com/boltlessengineer/NativeVim) to explore NVIM builtins over plugins
- [Shared Mini.nvim setups](https://github.com/echasnovski/mini.nvim/discussions/36)
- [echasnovski/nvim](https://github.com/echasnovski/nvim)

Plugins are organized according to category from [NeovimCraft](https://neovimcraft.com) like [astro-community](https://github.com/AstroNvim/astrocommunity/blob/59df499a5730504d1cad22073d9cd4a06ca03e0f/CONTRIBUTING.md)

My preference is for opinionated plugins that require minimal configuration.

- Accordingly, I've tried and removed:
    - AI: [parrot, avante, copilot](https://github.com/KyleKing/nvim/commit/8595a11da8866f6db5ebaa324a94db05d04cd2bb)
    - Bars and lines: [barbar](https://github.com/KyleKing/nvim/commit/186b25c#diff-a08294f302313640d70006877f8111d54587c50a998ceb770b56c704c90fb77a)
    - Buffers: [early-retirement.nvim for auto-closing deleted buffers](https://github.com/KyleKing/nvim/commit/00898cdc3c721d5445a7186cd786fd3c5af7dd9f)
    - Completion: [nvim-cmp](https://github.com/KyleKing/nvim/commit/c9c09d96ab3be993f52150eec3bed26d93615ab7)
    - Editing Support: [autopairs](https://github.com/KyleKing/nvim/commit/7e106f21d6645454b088b3089c3a3f2d067ffc7c), [dial](https://github.com/KyleKing/nvim/commit/bd4c99d), [nvim-ts-autotag](https://github.com/KyleKing/nvim/commit/460d16f07eb9d2ae49c1f59971948ac3a48f1dde), [cmp-spell, omni, etc.](https://github.com/KyleKing/nvim/commit/f3e92a6586af3dbb3f3735c05e1539a9aeb663c0), [Obsidian](https://github.com/KyleKing/nvim/commit/a60d7317b99ef60fa0677466a778958cf0d950fd), [text-case](https://github.com/KyleKing/nvim/commit/bd4c99d)
    - Git: [octo.nvim for Github](https://github.com/KyleKing/nvim/commit/1b3836019ce3943e6f7fcf7d96b728a1f9687c11), [vim-fugitive](https://github.com/KyleKing/nvim/commit/1b3836019ce3943e6f7fcf7d96b728a1f9687c11), [(most of) gitsigns](https://github.com/KyleKing/nvim/commit/0ef02b8422d68d1a266d6c53b28a4f112cd913d9)
    - LSP: [lsp-saga](https://github.com/KyleKing/nvim/commit/da614ec7db07a1e7245744d6f64776c6d04622e9), [trouble](https://github.com/KyleKing/nvim/commit/bd4c99d)
    - Marks: [harpoon](https://github.com/KyleKing/nvim/commit/d93f43420229cf43fdc7cab12576d1af1f34b4e6)
    - Motions: [neotab for tabbing out](https://github.com/KyleKing/nvim/commit/61a301f56c11ec01433badb53430368f0cff6ca9)
    - Search: [nvim-hlslens](https://github.com/KyleKing/nvim/commit/bd4c99d)
    - Programming Language Support: [markdown-preview](https://github.com/KyleKing/nvim/commit/3a3b0c667e1b755f26443e5968168db08b460ff3)
    - Session: [auto-session](https://github.com/KyleKing/nvim/commit/7ae6899681355904b83a757f28f014295a0321d8)
    - UI: [colorful-winsep](https://github.com/KyleKing/nvim/commit/bd4c99d), [nvim-web-devicons](https://github.com/KyleKing/nvim/commit/35a72a3e57db9650f5df97cc00433a436a32c8aa)
    - Utility: [dressing](https://github.com/KyleKing/nvim/commit/a58d2e9c71c25ac584cd1581295b8b68d0c516e9), [gx.nvim](https://github.com/KyleKing/nvim/commit/9da0fae), [noice](https://github.com/KyleKing/nvim/commit/8a30f4d03c8271756ecd1659e241013e78788834), [structlog](https://github.com/KyleKing/nvim/commit/9e10e13), [todo-comments](https://github.com/KyleKing/nvim/commit/bd4c99d)
- Removed, but would revisit
    - [kanban.nvim](https://github.com/KyleKing/nvim/commit/fba8b07ecd6b19495ba297a4e8a10f481eb0c939): removed while migrating to Mini.Deps and appeared to require `nvim-cmp`
- I've replaced:
    - [buffer-manager](https://github.com/KyleKing/nvim/commit/3bf83abcba6d9e36a0313013ea34d2b3a931a81b) with `telescope`
    - [hlargs](https://github.com/KyleKing/nvim/commit/9ce2a1c) with existing behavior from language LSPs
    - [indent-blankline](https://github.com/KyleKing/nvim/commit/3e823707087166c1718dc3e0a815a43d472e40a9) with `hlchunk` ([which was later removed](https://github.com/KyleKing/nvim/commit/a9596bb11332a77d74111b4ddd1cdb36b18ba47f))
    - [leap.nvim and alternative motion plugins](https://github.com/KyleKing/nvim/commit/d93f43420229cf43fdc7cab12576d1af1f34b4e6) with `flash.nvim`
    - [lualine](https://github.com/KyleKing/nvim/commit/1f4ce89) with `mini.statusline`
    - [luacheck](https://github.com/KyleKing/nvim/commit/a76ebc1) with `selene`
    - [mkdx](https://github.com/KyleKing/nvim/commit/61c56a2) with custom markdown/djot list editing and preview utilities
    - [nvim-cmp](https://github.com/KyleKing/nvim/commit/c9c09d96ab3be993f52150eec3bed26d93615ab7) with nvim 0.11+ built-in LSP completion
    - [quick-scope](https://github.com/KyleKing/nvim/commit/d93f43420229cf43fdc7cab12576d1af1f34b4e6) with `flash.nvim`
    - [reticle](https://github.com/KyleKing/nvim/commit/3297142) with `colorful-winsep`
    - [smart-splits](https://github.com/KyleKing/nvim/commit/c2ef609997d11df798b05f6a4b30c0fad42504e8) with `<c-w>` builtin
    - [telescope](https://github.com/KyleKing/nvim/commit/53b8119) with `mini.pick`
    - [toggleterm](https://github.com/KyleKing/nvim/commit/b0fe6bf) with custom terminal implementation
    - [ts-comments](https://github.com/KyleKing/nvim/commit/17cb743) with `mini.comment`
    - [vim-sandwich](https://github.com/KyleKing/nvim/commit/17cb743) with `mini.surround`
    - [which-key](https://github.com/KyleKing/nvim/commit/2712f73) with `mini.clue`
- And migrated from `Lazy.nvim` to `Mini.Deps` between <https://github.com/KyleKing/nvim/commit/97a2460d0d1090118908fee387eb68a1caae7665> and <https://github.com/KyleKing/nvim/commit/58d2cd4a18b0d5edd6c3091ffae95552faf9091f>

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

## Documentation

Plugin usage guides are available via `:h kyleking-neovim` within nvim.

## Testing

This config includes comprehensive tests using mini.test with parallel execution for speed.

### Quick Start

```vim
" In nvim (when cwd is config directory)
:RunTestsParallel        " Parallel workers (fastest, ~6-8 seconds)
<leader>tp               " Same as above
```

### Command Line

```bash
# Parallel execution (recommended)
MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
    -c "lua require('kyleking.utils.test_runner').run_tests_parallel()" \
    -c "sleep 10" -c "qall!"

# Single test file
MINI_DEPS_LATER_AS_NOW=1 nvim --headless \
    -c "lua MiniTest.run_file('lua/tests/custom/constants_spec.lua')" \
    -c "qall!"
```

### Commands

| Command                          | Keybind      | Speed        |
| -------------------------------- | ------------ | ------------ |
| `:RunTestsParallel`              | `<leader>tp` | ~6-8s (7-8x) |
| `:RunAllTests`                   | `<leader>ta` | ~20s (2x)    |
| `:RunFailedTests`                | `<leader>tf` | Variable     |
| `:RunTestsRandom [seed]`         | `<leader>tr` | ~20s         |
| `:RunTestsParallelRandom [seed]` | -            | ~6-8s        |

See `:h kyleking-neovim-testing` for complete documentation.
