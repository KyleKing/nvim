# Milestone 9: Final Verification

**Goal:** End-to-end verification and documentation

## Actions

1. Run full test suite: `nvim --headless -c "lua MiniTest.run()" -c "q"`
1. Fix any failing tests or startup errors
1. Test all LSP workflows manually:
    - Python: completion, diagnostics, formatting (ruff), linting
    - TypeScript: completion, diagnostics, formatting (prettier)
    - Lua: completion, diagnostics, formatting (stylua)
    - Go: completion, diagnostics, formatting (gofmt)
1. Test all pickers:
    - Files, buffers, grep, LSP (symbols, definitions, references)
    - Visual grep, help tags, resume
1. Test terminal modes:
    - Float toggle, horizontal, vertical
    - Lazygit integration with worktree support
1. Test git integration:
    - Gitsigns: hunks, blame, toggle deleted
    - Diffview: open, file history
1. Verify startup time: `nvim --startuptime startup.log`

## Testing

**Expected results:**

- All ~440 tests pass
- No errors in `:messages` on startup
- All workflows functional
- Startup time ≤ 120-150ms (20-30% improvement from ~150-200ms)

## Acceptance Criteria

- [ ] All tests pass (~440 tests)
- [ ] No startup errors (check `:messages`)
- [ ] All keybindings work
- [ ] LSP completion functional (Python, TS, Lua, Go)
- [ ] All pickers work (files, buffers, grep, LSP)
- [ ] Statusline displays correctly (normal + temp sessions)
- [ ] Terminal toggles work (float, horizontal, vertical)
- [ ] Git integration functional
- [ ] Startup time improved
- [ ] Documentation updated (README, comments)

## Commit

**Message:** "docs: final verification and documentation for modernized config"
