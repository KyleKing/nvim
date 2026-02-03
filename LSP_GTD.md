# LSP Navigation Test Fixtures (Go-to-Definition)

Test cases documenting LSP navigation behaviors discovered during monorepo investigation.

## Fixture: `lua/tests/docs/lsp_navigation.lua`

```lua
return {
    title = "LSP Navigation",
    see_also = { "lsp-buf", "vim.lsp.buf" },
    desc = "Navigate code using Language Server Protocol.",

    notes = {
        "`gd` is NOT bound by default in Neovim 0.11+.",
        "Default bindings: `gri` (implementation), `grr` (references), `K` (hover), `grn` (rename), `gra` (code action).",
        "Picker navigation shows multiple targets: `<leader>lgd` (definitions), `<leader>lgi` (implementations).",
        "In monorepos, `definition` may navigate to re-exports instead of actual source. Use `implementation` or pickers.",
        "Custom bindings: `<leader>cR` (references), `<leader>cr` (rename), `<leader>ca` (code actions).",
    },

    grammars = {
        {
            pattern = "gri",
            desc = "Go to implementation (Neovim default)",
            tests = {
                {
                    name = "navigate to function implementation",
                    -- TODO: Requires LSP server running and actual multi-file project
                    -- Challenge: Need to spawn LSP, create temp project structure
                    -- Possible approach: Use nvim_interaction_test with pre-created fixture directory
                    setup = {
                        fn = function()
                            -- Create temp TypeScript project:
                            -- package-b/utils.ts: export function calc() { return 1; }
                            -- package-b/index.ts: export { calc } from './utils';
                            -- package-a/main.ts: import { calc } from '../package-b';
                            -- Open main.ts, position on calc usage
                            -- Wait for ts_ls to attach
                        end,
                    },
                    keys = "gri",
                    expect = {
                        fn = function(ctx)
                            -- Should navigate to utils.ts (implementation)
                            -- NOT to index.ts (re-export)
                            local filename = vim.fn.expand("%:t")
                            assert(filename == "utils.ts", "Expected utils.ts, got " .. filename)
                        end,
                    },
                },
            },
        },

        {
            pattern = "grr",
            desc = "Find references (Neovim default)",
            tests = {
                {
                    name = "show all references in quickfix",
                    -- TODO: Similar setup challenges as gri
                    setup = {
                        fn = function()
                            -- Create project with multiple references to same symbol
                            -- file1.ts: export const FOO = 1;
                            -- file2.ts: import { FOO } from './file1'; console.log(FOO);
                            -- file3.ts: import { FOO } from './file1'; const x = FOO;
                        end,
                    },
                    keys = "grr",
                    expect = {
                        fn = function(ctx)
                            -- Check quickfix list populated with references
                            vim.wait(1000)
                            local qf = vim.fn.getqflist()
                            assert(#qf >= 2, "Expected at least 2 references, got " .. #qf)
                        end,
                    },
                },
            },
        },

        {
            pattern = "K",
            desc = "Hover documentation (Neovim default)",
            tests = {
                {
                    name = "show function signature",
                    setup = {
                        fn = function()
                            -- Create Lua file with documented function
                            local tmpfile = vim.fn.tempname() .. ".lua"
                            vim.fn.writefile({
                                "--- Calculate sum of two numbers",
                                "--- @param a number First number",
                                "--- @param b number Second number",
                                "--- @return number Sum",
                                "local function add(a, b)",
                                "  return a + b",
                                "end",
                                "",
                                "add(1, 2)",
                            }, tmpfile)
                            vim.cmd("edit " .. tmpfile)
                            vim.bo.filetype = "lua"
                            -- Wait for lua_ls
                            vim.wait(3000, function()
                                return #vim.lsp.get_clients({ bufnr = 0 }) > 0
                            end)
                            -- Position on 'add' in line 9
                            vim.api.nvim_win_set_cursor(0, {9, 0})
                        end,
                    },
                    keys = "K",
                    expect = {
                        fn = function(ctx)
                            -- Check that hover window opened
                            vim.wait(500)
                            local wins = vim.api.nvim_list_wins()
                            local hover_found = false
                            for _, win in ipairs(wins) do
                                local buf = vim.api.nvim_win_get_buf(win)
                                local ft = vim.bo[buf].filetype
                                if ft == "markdown" then  -- hover windows use markdown
                                    hover_found = true
                                    break
                                end
                            end
                            assert(hover_found, "Hover window not found")
                        end,
                    },
                },
            },
        },

        {
            pattern = "<leader>lgd",
            desc = "Find definitions (picker)",
            tests = {
                {
                    name = "show all definitions in picker",
                    -- TODO: Challenge - testing picker UI is complex
                    -- Picker needs to be interactive, can't easily snapshot
                    setup = {
                        fn = function()
                            -- Create monorepo scenario:
                            -- package-b/utils.ts: export function calc() {}
                            -- package-b/index.ts: export { calc } from './utils'
                            -- package-a/main.ts: import { calc } from '../package-b'
                            -- Open main.ts, position on calc
                        end,
                    },
                    keys = "<leader>lgd",
                    expect = {
                        fn = function(ctx)
                            -- Verify picker opened with MiniPick
                            vim.wait(500)
                            local picker_active = vim.b.minipick_config ~= nil
                            assert(picker_active, "Picker should be active")

                            -- TODO: Verify picker shows BOTH index.ts and utils.ts
                            -- Challenge: How to inspect picker items without selecting?
                            -- Possible: Use MiniPick.get_picker_items() if available
                        end,
                    },
                },
            },
        },

        {
            pattern = "<leader>lgi",
            desc = "Find implementations (picker)",
            tests = {
                {
                    name = "show implementations bypassing re-exports",
                    -- TODO: Same challenges as <leader>lgd
                    -- Key difference: implementation scope may skip re-exports
                    setup = {
                        fn = function()
                            -- Same monorepo setup as above
                        end,
                    },
                    keys = "<leader>lgi",
                    expect = {
                        fn = function(ctx)
                            -- Verify picker shows utils.ts (implementation)
                            -- May or may not show index.ts (re-export)
                            -- This is LSP server dependent
                        end,
                    },
                },
            },
        },

        {
            pattern = "<leader>cR",
            desc = "Find references (LSP direct)",
            tests = {
                {
                    name = "populate location list with references",
                    -- Similar to grr but custom binding
                    -- TODO: Verify it uses location list vs quickfix
                    expect = { snapshot = true },
                },
            },
        },

        {
            pattern = "]r / [r",
            desc = "Next/previous reference (vim-illuminate)",
            tests = {
                {
                    name = "jump to next highlighted reference",
                    before = {
                        "const foo = 1;",
                        "console.log(foo);",
                        "return foo;",
                    },
                    cursor = { 1, 6 },  -- on 'foo' in line 1
                    -- TODO: Requires vim-illuminate to highlight references first
                    -- May need setup to trigger highlighting
                    keys = "]r",
                    expect = {
                        cursor = { 2, 12 },  -- should jump to 'foo' in line 2
                    },
                },
                {
                    name = "jump to previous highlighted reference",
                    before = {
                        "const foo = 1;",
                        "console.log(foo);",
                        "return foo;",
                    },
                    cursor = { 3, 7 },  -- on 'foo' in line 3
                    keys = "[r",
                    expect = {
                        cursor = { 2, 12 },  -- should jump to 'foo' in line 2
                    },
                },
            },
        },

        {
            pattern = "<leader>lsc / lsC",
            desc = "Semantic calls analysis (codanna)",
            tests = {
                {
                    name = "show calls from symbol",
                    -- TODO: Requires codanna.nvim plugin and semantic analysis
                    -- This is beyond standard LSP - uses tree-sitter
                    keys = "<leader>lsc",
                    expect = {
                        fn = function(ctx)
                            -- Verify codanna picker opened
                            -- Challenge: Plugin-specific behavior
                        end,
                    },
                },
            },
        },
    },
}
```

## Implementation Challenges

### 1. LSP Server Dependency

**Problem:** Tests require actual LSP servers (ts_ls, pyright, lua_ls) to be running.

**Options:**

- Use `nvim_interaction_test` helper (already spawns fresh nvim instance)
- Create fixture directories with realistic project structures
- Accept longer test execution time for LSP to initialize

**Example structure:**

```lua
setup = {
    fn = function()
        local tmpdir = vim.fn.tempname()
        vim.fn.mkdir(tmpdir .. "/package-a", "p")
        vim.fn.mkdir(tmpdir .. "/package-b", "p")

        -- Create actual files
        vim.fn.writefile({"export function calc() { return 1; }"},
                        tmpdir .. "/package-b/utils.ts")
        vim.fn.writefile({"export { calc } from './utils';"},
                        tmpdir .. "/package-b/index.ts")

        -- Create package.json for root detection
        vim.fn.writefile({"{}"}, tmpdir .. "/package.json")

        -- Open and wait for LSP
        vim.cmd("edit " .. tmpdir .. "/package-a/main.ts")
        vim.wait(4000, function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
        end)
    end,
}
```

### 2. Picker UI Testing

**Problem:** MiniPick is interactive UI - hard to test without simulating user input.

**Options:**

- Test that picker opens (check `vim.b.minipick_config`)
- Inject test items instead of real LSP results
- Use `MiniPick.set_picker_items()` if available
- Accept limited testing (verify picker opens, not full interaction)

**Possible approach:**

```lua
expect = {
    fn = function(ctx)
        -- Verify picker is active
        local picker_active = vim.b.minipick_config ~= nil
        assert(picker_active, "Picker should be open")

        -- TODO: Inspect picker items if MiniPick exposes API
        -- Otherwise just verify picker opened successfully
    end,
}
```

### 3. Asynchronous LSP Responses

**Problem:** LSP responses are async, timing varies by server/system.

**Options:**

- Liberal use of `vim.wait()` with generous timeouts
- Poll for expected state changes
- Accept flaky tests on slow systems
- Mark as integration tests (slower, run less frequently)

**Example:**

```lua
keys = "gri",
expect = {
    fn = function(ctx)
        -- Wait for navigation to complete
        local target_reached = false
        vim.wait(2000, function()
            local current_file = vim.fn.expand("%:t")
            target_reached = current_file == "utils.ts"
            return target_reached
        end, 100)  -- check every 100ms

        assert(target_reached, "Did not navigate to utils.ts")
    end,
}
```

### 4. Monorepo Test Fixtures

**Problem:** Need realistic monorepo structure to test re-export behavior.

**Solution:** Create minimal but realistic fixture directories:

```
/tmp/test-monorepo/
├── package.json          (root marker)
├── package-a/
│   ├── tsconfig.json
│   └── main.ts          (imports from package-b)
└── package-b/
    ├── tsconfig.json
    ├── utils.ts         (actual implementation)
    └── index.ts         (re-exports from utils)
```

Keep TypeScript configs minimal:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs"
  }
}
```

## Alternative: Simpler "Existence" Tests

If full LSP testing proves too complex for Phase 1, start with simpler tests:

```lua
{
    pattern = "gri",
    desc = "Go to implementation (Neovim default)",
    tests = {
        {
            name = "keybinding exists",
            expect = {
                fn = function(ctx)
                    -- Just verify the mapping exists
                    local maps = vim.api.nvim_get_keymap("n")
                    local gri_found = false
                    for _, map in ipairs(maps) do
                        if map.lhs == "gri" then
                            gri_found = true
                            break
                        end
                    end
                    assert(gri_found, "gri mapping not found")
                end,
            },
        },
    },
},
```

However, per AGENTS.md test quality guidelines, these "existence only" tests should be avoided. Better to have fewer, higher-quality behavioral tests.

## Recommendation

**Phase 1:** Implement infrastructure for simpler plugins (surround, comment, move) that don't require external services.

**Phase 2:** Tackle LSP navigation with:

1. Helper function to create monorepo fixture directories
1. Generous timeouts and polling for LSP readiness
1. Focus on behaviors we can reliably test (navigation occurred, picker opened)
1. Accept some test flakiness as cost of integration testing

**Phase 3:** Consider separate "integration test" category with longer timeouts, run less frequently.

## Test Priority

From easiest to hardest to implement:

1. **`]r` / `[r`** (vim-illuminate) - Simpler, buffer-local behavior
1. **`K`** (hover) - Can test hover window opened
1. **`grr`** (references) - Can test quickfix populated
1. **`gri`** (implementation) - Requires full monorepo fixture
1. **`<leader>lgd/lgi`** (pickers) - Requires picker UI testing
1. **`<leader>lsc`** (codanna) - Plugin-specific, most complex

Start with `]r` / `[r` tests to validate the fixture framework, then progressively tackle harder cases.
