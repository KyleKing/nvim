# Plugin Snapshot Management

This guide explains how to use mini.deps snapshots for reproducible plugin versions.

## Overview

mini.deps provides snapshot functionality to freeze plugin versions at specific commits. This ensures:

- **Reproducibility:** Same plugin versions across machines and team members
- **Stability:** Test updates before rolling them out
- **Rollback:** Easy recovery from problematic plugin updates

Snapshots are stored in the `mini-deps-snap/` directory.

## Creating Snapshots

### Manual Snapshot Creation

In Neovim, save a snapshot of all current plugin versions:

```vim
:lua MiniDeps.snap_save()
```

This creates/updates snapshot files in `mini-deps-snap/` with the current commit SHAs of all installed plugins.

### Creating Named Snapshots

For specific milestones or configurations:

```vim
:lua MiniDeps.snap_save("stable-2024-02")
```

This creates a snapshot file: `mini-deps-snap/stable-2024-02`

### Automated Snapshot Creation

Add to your configuration to automatically save snapshots:

```lua
-- In lua/kyleking/setup-deps.lua or similar
vim.api.nvim_create_user_command("SnapshotSave", function()
    local date = os.date("%Y-%m-%d")
    MiniDeps.snap_save("snapshot-" .. date)
    vim.notify("Snapshot saved: snapshot-" .. date, vim.log.levels.INFO)
end, {})
```

Then use: `:SnapshotSave`

## Loading Snapshots

### Load Default Snapshot

Restore plugins to the versions in the default snapshot:

```vim
:lua MiniDeps.snap_load()
```

This reads from `mini-deps-snap/default` and updates all plugins to the specified commits.

### Load Named Snapshot

Restore a specific snapshot:

```vim
:lua MiniDeps.snap_load("stable-2024-02")
```

### Automatic Snapshot Loading

To always load a specific snapshot on startup, add to `lua/kyleking/setup-deps.lua`:

```lua
-- After plugin setup
MiniDeps.snap_load() -- Load default snapshot
```

**Warning:** This prevents plugins from auto-updating. Use only for production environments.

## Snapshot Workflow

### Recommended Workflow for Personal Use

1. **Before Major Updates:**
   ```vim
   :lua MiniDeps.snap_save("pre-update-" .. os.date("%Y%m%d"))
   :DepsUpdate  " Update all plugins
   ```

2. **Test New Versions:**
   - Use Neovim normally for a few days
   - Check for issues with plugins

3. **Rollback if Needed:**
   ```vim
   :lua MiniDeps.snap_load("pre-update-20240215")
   ```

4. **Commit Stable Snapshot:**
   ```bash
   git add mini-deps-snap/
   git commit -m "chore: snapshot stable plugin versions"
   ```

### Recommended Workflow for Teams

1. **Create Stable Snapshots:**
   - One team member creates and tests a snapshot
   - Commits to version control

2. **Team Members Load Snapshot:**
   - Pull latest changes
   - In Neovim: `:lua MiniDeps.snap_load()`

3. **Update Cycle:**
   - Scheduled plugin updates (e.g., monthly)
   - Test in dev environment
   - Commit new snapshot
   - Roll out to team

## Snapshot File Format

Snapshot files are simple text files with format:

```
<plugin-name> <commit-sha>
mini.nvim abc123def456...
nvim-treesitter 789ghi012jkl...
```

Example `mini-deps-snap/default`:

```
mini.nvim 8e8a8e9b9c5e3f1a2b3c4d5e6f7a8b9c0d1e2f3a
nvim-treesitter 1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9g0h
conform.nvim 4b5c6d7e8f9g0h1i2j3k4l5m6n7o8p9q0r1s2t3u
nvim-lint 5c6d7e8f9g0h1i2j3k4l5m6n7o8p9q0r1s2t3u4v
```

You can manually edit these files to pin specific plugins to older versions.

## Common Use Cases

### Use Case 1: Pin a Problematic Plugin

If a plugin update breaks functionality:

1. Find the working commit SHA:
   ```bash
   cd ~/.local/share/nvim/mini-deps/nvim-treesitter
   git log --oneline -10
   ```

2. Edit snapshot file:
   ```
   nvim-treesitter abc123  # Old working commit
   ```

3. Load snapshot:
   ```vim
   :lua MiniDeps.snap_load()
   ```

### Use Case 2: Test Plugin Updates Safely

1. Save current state:
   ```vim
   :lua MiniDeps.snap_save("backup")
   ```

2. Update plugins:
   ```vim
   :DepsUpdate
   ```

3. If issues occur, rollback:
   ```vim
   :lua MiniDeps.snap_load("backup")
   ```

### Use Case 3: CI/CD Integration

Ensure consistent plugin versions in CI:

```yaml
# .github/workflows/test.yml
- name: Restore Plugin Snapshot
  run: |
    nvim --headless -c "lua MiniDeps.snap_load()" -c "qall"
    
- name: Run Tests
  run: |
    nvim --headless -c "lua MiniTest.run()" -c "qall"
```

## Best Practices

### ✅ Do

1. **Commit Snapshots to Version Control**
   - Ensures team consistency
   - Enables rollback

2. **Create Snapshots Before Major Updates**
   - Easy recovery if issues arise

3. **Use Named Snapshots for Milestones**
   - Example: `stable-before-nvim-0.11-upgrade`

4. **Test Thoroughly Before Committing Snapshots**
   - Run full test suite
   - Test daily workflows

5. **Document Snapshot Purpose**
   ```bash
   git commit -m "chore: snapshot plugins for nvim 0.11 compatibility"
   ```

### ❌ Don't

1. **Don't Auto-Load Snapshots in Development**
   - Prevents getting plugin updates
   - Only use in production/CI

2. **Don't Ignore Snapshot Files in .gitignore**
   - They should be versioned for team consistency

3. **Don't Leave Old Snapshots Indefinitely**
   - Clean up outdated snapshots periodically

4. **Don't Mix Manual Updates and Snapshots**
   - Choose one approach: either pinned versions or auto-updates

## Snapshot Management Commands

### Custom Commands for Convenience

Add to `lua/kyleking/core/keymaps.lua` or similar:

```lua
-- Snapshot management commands
vim.api.nvim_create_user_command("SnapshotSave", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    MiniDeps.snap_save(name)
    local snap_name = name or "default"
    vim.notify("Snapshot saved: " .. snap_name, vim.log.levels.INFO)
end, { nargs = "?" })

vim.api.nvim_create_user_command("SnapshotLoad", function(opts)
    local name = opts.args ~= "" and opts.args or nil
    MiniDeps.snap_load(name)
    local snap_name = name or "default"
    vim.notify("Snapshot loaded: " .. snap_name, vim.log.levels.INFO)
end, { nargs = "?" })

vim.api.nvim_create_user_command("SnapshotList", function()
    local snap_dir = vim.fn.stdpath("config") .. "/mini-deps-snap"
    local snapshots = vim.fn.readdir(snap_dir)
    if #snapshots == 0 then
        vim.notify("No snapshots found", vim.log.levels.WARN)
        return
    end
    vim.notify("Available snapshots:\n" .. table.concat(snapshots, "\n"), vim.log.levels.INFO)
end, {})
```

Usage:
```vim
:SnapshotSave                " Save default snapshot
:SnapshotSave my-snapshot    " Save named snapshot
:SnapshotLoad                " Load default snapshot
:SnapshotLoad my-snapshot    " Load named snapshot
:SnapshotList                " List all snapshots
```

### Keybindings

Add convenient keybindings:

```lua
vim.keymap.set("n", "<leader>ps", ":SnapshotSave<CR>", { desc = "Save plugin snapshot" })
vim.keymap.set("n", "<leader>pl", ":SnapshotLoad<CR>", { desc = "Load plugin snapshot" })
vim.keymap.set("n", "<leader>pL", ":SnapshotList<CR>", { desc = "List plugin snapshots" })
```

## Troubleshooting

### Snapshot Load Fails

**Symptom:** Error when loading snapshot

**Solutions:**

1. Check snapshot file exists:
   ```bash
   ls -la mini-deps-snap/
   ```

2. Verify snapshot file format (no extra spaces/newlines)

3. Try updating plugins first, then load:
   ```vim
   :DepsUpdate
   :lua MiniDeps.snap_load()
   ```

### Plugins Not Updating

**Symptom:** `:DepsUpdate` does nothing

**Cause:** Snapshot auto-load is enabled

**Solution:** Remove `MiniDeps.snap_load()` from startup config, or use `:DepsUpdateForce`

### Merge Conflicts in Snapshots

**Symptom:** Git merge conflicts in `mini-deps-snap/`

**Solution:**

1. Accept both versions (keep all unique entries)
2. Remove duplicate entries
3. Test by loading the merged snapshot:
   ```vim
   :lua MiniDeps.snap_load()
   ```

## Advanced: Snapshot Comparison

Compare two snapshots to see what changed:

```bash
# Show differences between two snapshots
diff mini-deps-snap/old-snapshot mini-deps-snap/new-snapshot

# Or use git diff if both are committed
git diff HEAD~1 mini-deps-snap/default
```

Create a helper function:

```lua
-- Add to lua/kyleking/utils.lua or similar
M.compare_snapshots = function(snap1, snap2)
    snap1 = snap1 or "default"
    snap2 = snap2 or "default"
    
    local snap_dir = vim.fn.stdpath("config") .. "/mini-deps-snap"
    local file1 = snap_dir .. "/" .. snap1
    local file2 = snap_dir .. "/" .. snap2
    
    vim.cmd("vsplit " .. file1)
    vim.cmd("diffthis")
    vim.cmd("vsplit " .. file2)
    vim.cmd("diffthis")
end
```

Usage:
```vim
:lua require("kyleking.utils").compare_snapshots("old", "new")
```

## See Also

- [mini.deps Documentation](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-deps.md)
- `CLAUDE.md` - General development guide
- `doc/src/config.md` - Configuration overview
- `lua/kyleking/setup-deps.lua` - Plugin setup file

## Resources

- mini.deps GitHub: https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-deps.md
- mini.nvim ecosystem: https://github.com/echasnovski/mini.nvim
