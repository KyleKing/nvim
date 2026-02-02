# Local Configuration Guide

This guide explains how to use `lua/kyleking/deps/local.lua` for machine-specific and experimental configurations.

## Overview

The `local.lua` file is intended for:

- **Machine-specific settings:** Configurations that differ between your laptop, desktop, work machine, etc.
- **Experimental plugins:** Testing new plugins before adding them to the main configuration
- **Personal preferences:** Settings you don't want to commit to version control
- **Project-specific overrides:** Temporary adjustments for specific projects

## File Location

```
lua/kyleking/deps/local.lua
```

This file is loaded automatically during the plugin initialization phase, after all other `deps/*.lua` files.

## Basic Structure

```lua
-- lua/kyleking/deps/local.lua
local MiniDeps = require("mini.deps")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Example: Machine-specific plugin
later(function()
    add("experimental/plugin")
    require("plugin").setup({
        -- Plugin configuration
    })
end)

-- Example: Override existing settings
later(function()
    -- Modify an existing keymap
    vim.keymap.set("n", "<leader>t", function()
        print("Local override")
    end, { desc = "Local test command" })
end)
```

## Common Use Cases

### Use Case 1: Testing New Plugins

Before adding a plugin to your main configuration, test it in `local.lua`:

```lua
later(function()
    -- Testing a new fuzzy finder
    add("ibhagwan/fzf-lua")
    require("fzf-lua").setup({
        winopts = {
            height = 0.85,
            width = 0.80,
        },
    })
    
    -- Add temporary keybinding to test
    vim.keymap.set("n", "<leader>ff", function()
        require("fzf-lua").files()
    end, { desc = "[TEST] FZF files" })
end)
```

Once satisfied, move the configuration to an appropriate `deps/*.lua` file.

### Use Case 2: Machine-Specific Settings

Different machines may have different capabilities or preferences:

```lua
-- Check hostname or environment variable
local hostname = vim.fn.hostname()

if hostname == "work-laptop" then
    later(function()
        -- Work-specific plugins or settings
        add("work/enterprise-plugin")
        require("enterprise-plugin").setup({
            api_endpoint = "https://internal.company.com",
        })
    end)
elseif hostname == "home-desktop" then
    later(function()
        -- Personal development plugins
        add("personal/hobby-plugin")
    end)
end
```

Or use environment variables:

```lua
local is_work = vim.env.WORK_ENV == "1"

if is_work then
    later(function()
        -- Work-specific configuration
    end)
end
```

### Use Case 3: Experimental Features

Try new mini.nvim modules or features:

```lua
later(function()
    -- Testing unreleased mini.nvim modules
    local MiniExperimental = require("mini.experimental")
    if MiniExperimental then
        MiniExperimental.setup({
            -- New feature configuration
        })
    end
end)
```

### Use Case 4: Performance Testing

Add diagnostics or profiling temporarily:

```lua
later(function()
    -- Startup time logging
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            local stats = vim.loop.getrusage()
            print(string.format("Startup time: %dms", vim.loop.hrtime() / 1000000))
        end,
    })
end)
```

### Use Case 5: Project-Specific Settings

Override settings when working on specific projects:

```lua
later(function()
    vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
            local cwd = vim.fn.getcwd()
            
            -- Project-specific settings
            if string.match(cwd, "/specific%-project/") then
                -- Override tab width for this project
                vim.opt_local.tabstop = 2
                vim.opt_local.shiftwidth = 2
                
                -- Load project-specific plugin
                add("project/specific-linter")
                require("specific-linter").setup()
            end
        end,
    })
end)
```

## Version Control

### Option 1: Not Tracked (Recommended for Personal Use)

Add to `.gitignore`:

```gitignore
lua/kyleking/deps/local.lua
```

**Pros:**
- True machine-local configuration
- No risk of committing sensitive data
- Personal settings don't affect others

**Cons:**
- Need to recreate on new machines
- Can't track changes over time

### Option 2: Tracked with Template (Recommended for Teams)

Commit a template file and ignore the actual `local.lua`:

```bash
# Commit this
git add lua/kyleking/deps/local.lua.template

# Ignore the actual file
echo "lua/kyleking/deps/local.lua" >> .gitignore
```

**Template file** (`local.lua.template`):

```lua
-- lua/kyleking/deps/local.lua.template
-- Copy this file to local.lua and customize for your machine
--
-- cp lua/kyleking/deps/local.lua.template lua/kyleking/deps/local.lua

local MiniDeps = require("mini.deps")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Example: Machine-specific plugin
-- later(function()
--     add("username/plugin")
--     require("plugin").setup({})
-- end)

-- Example: Environment-specific settings
-- local hostname = vim.fn.hostname()
-- if hostname == "your-machine" then
--     later(function()
--         -- Your settings
--     end)
-- end
```

**Setup on new machine:**
```bash
cp lua/kyleking/deps/local.lua.template lua/kyleking/deps/local.lua
nvim lua/kyleking/deps/local.lua  # Customize
```

### Option 3: Fully Tracked (Simple but Less Flexible)

Commit `local.lua` to version control:

```bash
git add lua/kyleking/deps/local.lua
```

**Pros:**
- Simple setup on new machines
- Track changes over time

**Cons:**
- Same settings on all machines
- Risk of committing sensitive data

## Best Practices

### ✅ Do

1. **Use for Experimentation**
   - Test plugins before committing to main config
   - Try new features safely

2. **Document Your Overrides**
   ```lua
   -- Temporary: Testing fzf-lua as mini.pick alternative
   -- TODO: Decide by 2024-03-01 which to keep
   ```

3. **Clean Up Regularly**
   - Remove abandoned experiments
   - Move stable configs to appropriate files

4. **Use Conditional Logic**
   ```lua
   if vim.fn.hostname() == "my-machine" then
       -- Machine-specific code
   end
   ```

5. **Comment Extensively**
   - Future you will appreciate the context
   - Explain *why* settings are different

### ❌ Don't

1. **Don't Put Critical Config Here**
   - Keep essential settings in main config files
   - `local.lua` should be optional

2. **Don't Commit Sensitive Data**
   - API keys, tokens, credentials
   - Use environment variables instead

3. **Don't Let It Grow Unbounded**
   - Regularly review and clean up
   - Move successful experiments to main config

4. **Don't Override Core Behavior Silently**
   - Document significant overrides
   - Consider if change belongs in main config

5. **Don't Use for Team Settings**
   - Use main config files for team-shared settings
   - `local.lua` is for personal/machine-specific only

## Examples

### Example 1: Minimal Local Config (Empty)

```lua
-- lua/kyleking/deps/local.lua
-- This file is intentionally empty
-- Machine-specific or experimental configuration can be added here
-- See doc/src/local-configuration.md for examples

local MiniDeps = require("mini.deps")
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- Your local configuration here
```

### Example 2: Testing Multiple Alternatives

```lua
-- Testing different completion plugins
later(function()
    local use_nvim_cmp = false  -- Toggle to test
    
    if use_nvim_cmp then
        add("hrsh7th/nvim-cmp")
        require("cmp").setup({
            -- Configuration
        })
    else
        -- Use built-in completion (default)
        -- No additional setup needed
    end
end)
```

### Example 3: Development Environment Detection

```lua
later(function()
    local in_dev_container = vim.env.REMOTE_CONTAINERS == "true"
    local in_wsl = vim.fn.has("wsl") == 1
    
    if in_dev_container then
        -- Dev container specific settings
        vim.opt.clipboard = ""  -- Disable system clipboard in container
    elseif in_wsl then
        -- WSL specific settings
        vim.opt.clipboard = "unnamedplus"
        vim.g.clipboard = {
            name = "WslClipboard",
            copy = {
                ["+"] = "clip.exe",
                ["*"] = "clip.exe",
            },
            paste = {
                ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
                ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            },
        }
    end
end)
```

### Example 4: Temporary Debug Logging

```lua
later(function()
    -- Debug LSP attachment issues
    local debug_lsp = true
    
    if debug_lsp then
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                print(string.format(
                    "[DEBUG] LSP attached: %s (bufnr=%d)",
                    client and client.name or "unknown",
                    args.buf
                ))
            end,
        })
    end
end)
```

## Integration with Main Config

The `local.lua` file is loaded in `lua/kyleking/setup-deps.lua`:

```lua
-- Load all plugin configurations (including local.lua)
for _, file in ipairs(dep_files) do
    require("kyleking.deps." .. file)
end
```

This means `local.lua` can:
- Override previous settings
- Add new plugins
- Modify existing keymaps
- Create new autocommands

However, it **cannot**:
- Remove plugins added earlier
- Prevent earlier configurations from loading

## Troubleshooting

### local.lua Not Loading

**Check:**
1. File exists at `lua/kyleking/deps/local.lua`
2. File has correct syntax (no errors)
3. Run `:checkhealth` to see if there are issues

**Debug:**
```lua
-- Add to top of local.lua
print("local.lua is loading!")
```

### Settings Not Applied

**Possible causes:**
1. Wrapped in `later()` but needs `now()`
2. Override happens before main config sets value
3. Setting is buffer-local (`vim.opt_local` vs `vim.opt`)

**Solution:** Use `vim.schedule()` or move to `later()` callback:

```lua
later(function()
    vim.schedule(function()
        -- Ensure this runs after other configs
        vim.opt.number = false
    end)
end)
```

## See Also

- `CLAUDE.md` - General development guide
- `doc/src/config.md` - Configuration overview
- `lua/kyleking/setup-deps.lua` - Plugin loader
- `doc/src/plugin-snapshots.md` - Plugin version management
