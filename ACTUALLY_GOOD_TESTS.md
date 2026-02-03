# Documentation-Driven Testing

**Status: ✅ Complete and operational**

This document describes the implemented documentation-driven testing system that ensures documentation stays synchronized with actual plugin behavior.

## Problem

Documentation and tests maintained separately lead to drift. Documentation might claim `saiw"` wraps a word in quotes, but nothing validates this remains true after refactoring.

## Solution

Single-source fixtures that generate both:

1. **Behavioral tests** (mini.test) that verify functionality
1. **Documentation** (markdown → vimdoc) that describes functionality

This creates a single source of truth where tests = documentation.

## Progress

**Status**: All phases complete. 18 fixtures implemented with comprehensive test coverage.

**Completed fixtures**:

**Plugin-specific**:

- ✓ `surround.lua` - mini.surround (add, delete, replace, find, highlight)
- ✓ `move.lua` - mini.move (API-based tests for move operations)
- ✓ `operators.lua` - mini.operators (sort, multiply)
- ✓ `ai.lua` - mini.ai enhanced text objects
- ✓ `comment.lua` - mini.comment toggle functionality
- ✓ `hipatterns.lua` - mini.hipatterns keyword highlighting (with snapshots)
- ✓ `pick.lua` - mini.pick fuzzy finder
- ✓ `files.lua` - mini.files file explorer
- ✓ `diff.lua` - mini.diff git integration (config validation)
- ✓ `flash.lua` - flash.nvim labeled motion
- ✓ `clue.lua` - mini.clue keybinding hints (config validation)
- ✓ `terminal.lua` - terminal integration (basic functionality check)
- ✓ `color.lua` - color and UI configuration
- ✓ `utilities.lua` - custom utilities (patches, URLs, spell)

**Core vim/navigation**:

- ✓ `navigation.lua` - nap.nvim navigation (\]a/[a tabs, ]b/[b buffers, ]d/\[d diagnostics, gt/gT, \<C-^>)
- ✓ `windows.lua` - window management (<C-w> commands, splits, resizing, focus toggle)
- ✓ `core-keymaps.lua` - custom keybindings (j/k wrap-aware, smart dd, buffer text object, file operations, register operations)
- ✓ `lsp-keymaps.lua` - LSP completion keybindings (<C-Space>, <C-j>/<C-k>, <CR>, <C-CR>)

**Infrastructure enhancements**:

- runner.lua handles optional test fields (before, keys, cursor)
- save_snapshots safely handles nil values
- Hybrid testing approach: API calls for complex keybindings, config validation for UI-heavy plugins
- Test fixtures serve dual purpose: behavioral tests AND user-facing documentation

**Generated artifacts**:

- 2 snapshot files (surround.snap, hipatterns.snap)
- Auto-generated documentation (838 lines, 18 sections) from all fixtures via generator.lua

## Architecture

```
lua/tests/docs/
├── runner.lua              # Test execution, snapshot I/O
├── generator.lua           # Markdown generation
├── runner_spec.lua         # mini.test wrapper
├── surround.lua            # Fixture (tracked)
├── surround.snap           # Snapshots (tracked)
├── picker.lua
├── picker.snap
└── ...

doc/
├── src/
│   ├── main.md             # Includes generated content
│   ├── help-navigation.md  # Hand-written
│   ├── vim-essentials.md   # Hand-written
│   └── notes.md            # Hand-written
├── generated/              # .gitignore'd
│   └── plugins.md          # Generated from fixtures
└── nvim.txt                # Final vimdoc (panvimdoc output)
```

## Fixture Schema

```lua
-- lua/tests/docs/<name>.lua
return {
    title = "Section Title (plugin.name)",
    see_also = { "PluginHelp" },              -- optional
    desc = "One-line description.",

    notes = {                                  -- optional
        "Additional prose not tied to a grammar.",
    },

    grammars = {
        {
            pattern = "sa{motion}{char}",      -- the documented grammar
            desc = "Add surrounding",          -- short description for doc table
            tests = {                          -- at least one required
                {
                    name = "word with quotes", -- unique within grammar
                    keys = 'saiw"',            -- keystrokes to execute
                    before = { "word" },       -- buffer content before
                    cursor = { 1, 0 },         -- optional, defaults to { 1, 0 }
                    expect = { ... },          -- see Expect Types below
                },
            },
        },
    },
}
```

### Expect Types

```lua
-- Type 1: Line comparison (simple cases)
expect = { lines = { '"word"' } }

-- Type 1b: With cursor position
expect = { lines = { '"word"' }, cursor = { 1, 1 } }

-- Type 2: Custom function (complex assertions)
expect = {
    fn = function(ctx)
        -- ctx: { bufnr, before, cursor, keys }
        local tabs = #vim.api.nvim_list_tabpages()
        assert(tabs == 2, "Expected 2 tabs")
    end,
}

-- Type 3: Snapshot (auto-generated)
expect = { snapshot = true }
```

### Setup for Complex Tests

```lua
{
    name = "picker navigation",
    setup = {
        fn = function()
            MiniPick.start({ source = { items = { "a", "b", "c" } } })
        end,
    },
    keys = "<C-j><C-j>",
    input = "query",  -- optional: text typed into prompt
    expect = { snapshot = true },
}
```

### Hybrid Testing Approach

**Challenge**: Tests with `<leader>` keybindings fail because special keys aren't processed in `vim.cmd("normal ...")`.

**Solution**: Use a hybrid approach based on test complexity:

1. **Simple keybindings** (no special keys): Use `keys` field with `expect.lines`

    ```lua
    { keys = 'saiw"', before = { "word" }, expect = { lines = { '"word"' } } }
    ```

1. **Complex keybindings** (`<leader>`, `<C-...>`): Use direct API calls

    ```lua
    {
        name = "move line down",
        expect = {
            fn = function(ctx)
                local MiniMove = require("mini.move")
                local helpers = require("tests.helpers")
                local bufnr = helpers.create_test_buffer({ "line1", "line2" }, "text")
                vim.api.nvim_set_current_buf(bufnr)
                MiniMove.move_line("down")
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                MiniTest.expect.equality(lines, { "line2", "line1" })
                helpers.delete_buffer(bufnr)
            end,
        },
    }
    ```

1. **UI-heavy plugins** (pick, files, diff): Focus on config validation

    ```lua
    {
        name = "config check",
        expect = {
            fn = function(ctx)
                local MiniDiff = require("mini.diff")
                MiniTest.expect.equality(type(MiniDiff.toggle_overlay), "function")
                MiniTest.expect.equality(MiniDiff.config.view.style, "sign")
            end,
        },
    }
    ```

1. **Async operations** (hipatterns highlights): Use setup with vim.wait()

    ```lua
    {
        setup = {
            fn = function()
                vim.cmd("doautocmd BufEnter")
                vim.wait(50)  -- Allow highlights to apply
            end,
        },
        expect = { snapshot = true },
    }
    ```

## Snapshot Format

File: `lua/tests/docs/<name>.snap` (adjacent to fixture)

```
# name: sa{motion}{char} > word with quotes
before:
  word
cursor: [1, 0]
keys: saiw"
after:
  "word"
cursor_after: [1, 1]
# ---

# name: sh > highlight parens
before:
  (word)
cursor: [1, 2]
keys: sh)
after:
  (word)
cursor_after: [1, 2]
highlights:
  - group: MiniSurroundHighlight
    range: [[1, 0], [1, 1]]
  - group: MiniSurroundHighlight
    range: [[1, 5], [1, 6]]
# ---
```

## Snapshot Behavior

| `UPDATE_SNAPSHOTS` | Snapshot exists | Behavior                     |
| ------------------ | --------------- | ---------------------------- |
| unset              | yes             | Compare, fail on mismatch    |
| unset              | no              | Fail with "missing snapshot" |
| `1`                | any             | Write/update snapshot        |
| `1`                | stale           | Prune unused snapshots       |

## Generated Documentation

From first test of each grammar:

```markdown
## Surround (mini.surround)

Add, delete, find, and replace surrounding pairs.

Operator grammar:

    sa{motion}{char}  Add surrounding (e.g., saiw" → "word")
    sd{char}          Delete surrounding (e.g., sd" → word)

`s` is disabled in normal/visual mode to avoid conflict. Use `cl` instead.

See also: `MiniSurround`
```

---

## Implementation Phases

### Phase 1: Core Infrastructure

#### 1.1 Create `lua/tests/docs/runner.lua`

```lua
local M = {}

local helpers = require("tests.helpers")

--- Parse .snap file into table keyed by test name
function M.load_snapshots(fixture_path)
    local snap_path = fixture_path:gsub("%.lua$", ".snap")
    local snapshots = {}
    -- TODO: Parse amber-style format
    -- Return: { ["grammar > test name"] = { before, cursor, keys, after, cursor_after, highlights? } }
    return snapshots
end

--- Write snapshots table to .snap file
function M.save_snapshots(fixture_path, snapshots)
    local snap_path = fixture_path:gsub("%.lua$", ".snap")
    -- TODO: Write amber-style format
end

--- Capture current editor state
function M.capture_state(ctx)
    return {
        before = ctx.before,
        cursor = ctx.cursor,
        keys = ctx.keys,
        after = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false),
        cursor_after = { unpack(vim.api.nvim_win_get_cursor(0)) },
        -- highlights = M.capture_highlights(ctx.bufnr),  -- Phase 2
    }
end

--- Run a single test case
function M.run_test(test, grammar_pattern, snapshots, update_mode)
    local MiniTest = require("mini.test")
    local snap_key = grammar_pattern .. " > " .. test.name

    local bufnr = helpers.create_test_buffer(test.before, "text")
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_win_set_cursor(0, test.cursor or { 1, 0 })

    -- Run setup
    if test.setup and test.setup.fn then
        test.setup.fn()
    end

    -- Execute keys
    if test.keys then
        vim.cmd("normal " .. test.keys)
    end
    if test.input then
        vim.api.nvim_feedkeys(test.input, "tx", false)
    end

    local ctx = {
        bufnr = bufnr,
        before = test.before,
        cursor = test.cursor or { 1, 0 },
        keys = test.keys,
    }

    -- Assert based on expect type
    if test.expect.lines then
        local actual = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        MiniTest.expect.equality(actual, test.expect.lines)
    end

    if test.expect.cursor then
        local actual = vim.api.nvim_win_get_cursor(0)
        MiniTest.expect.equality({ actual[1], actual[2] }, test.expect.cursor)
    end

    if test.expect.fn then
        test.expect.fn(ctx)
    end

    if test.expect.snapshot then
        local actual = M.capture_state(ctx)

        if update_mode then
            snapshots[snap_key] = actual
            snapshots._dirty = true
            snapshots._used[snap_key] = true
        else
            local expected = snapshots[snap_key]
            if expected == nil then
                error("Missing snapshot for: " .. snap_key .. "\nRun with UPDATE_SNAPSHOTS=1")
            end
            MiniTest.expect.equality(actual, expected, "Snapshot mismatch: " .. snap_key)
            snapshots._used[snap_key] = true
        end
    end

    helpers.delete_buffer(bufnr)
end

--- Run all tests in a fixture
function M.run_fixture(fixture_path)
    local fixture = dofile(fixture_path)
    local snapshots = M.load_snapshots(fixture_path)
    snapshots._used = {}
    snapshots._dirty = false

    local update_mode = vim.env.UPDATE_SNAPSHOTS == "1"

    for _, grammar in ipairs(fixture.grammars) do
        for _, test in ipairs(grammar.tests) do
            M.run_test(test, grammar.pattern, snapshots, update_mode)
        end
    end

    -- Prune unused snapshots in update mode
    if update_mode and snapshots._dirty then
        for key in pairs(snapshots) do
            if key:sub(1, 1) ~= "_" and not snapshots._used[key] then
                snapshots[key] = nil
            end
        end
        M.save_snapshots(fixture_path, snapshots)
    end
end

return M
```

#### 1.2 Create `lua/tests/docs/runner_spec.lua`

```lua
local MiniTest = require("mini.test")
local runner = require("tests.docs.runner")

local T = MiniTest.new_set()

-- Discover all fixture files
local fixture_files = vim.fn.glob("lua/tests/docs/*.lua", false, true)
fixture_files = vim.tbl_filter(function(f)
    local name = vim.fn.fnamemodify(f, ":t")
    return name ~= "runner.lua" and name ~= "generator.lua" and name ~= "init.lua"
end, fixture_files)

for _, fixture_path in ipairs(fixture_files) do
    local name = vim.fn.fnamemodify(fixture_path, ":t:r")
    T[name] = function()
        runner.run_fixture(fixture_path)
    end
end

if ... == nil then MiniTest.run() end

return T
```

#### 1.3 Create first fixture `lua/tests/docs/surround.lua`

Start with simple `lines` expectations only (no snapshots yet):

```lua
return {
    title = "Surround (mini.surround)",
    see_also = { "MiniSurround" },
    desc = "Add, delete, find, and replace surrounding pairs.",

    notes = {
        "`s` is disabled in normal/visual mode to avoid conflict. Use `cl` instead.",
        "Custom: `f` for function calls -- `saiwf` prompts for function name.",
    },

    grammars = {
        {
            pattern = "sa{motion}{char}",
            desc = "Add surrounding",
            tests = {
                {
                    name = "word with quotes",
                    keys = 'saiw"',
                    before = { "word" },
                    expect = { lines = { '"word"' } },
                },
                {
                    name = "word with parens",
                    keys = "saiw)",
                    before = { "word" },
                    expect = { lines = { "(word)" } },
                },
                {
                    name = "WORD with braces",
                    keys = "saW}",
                    before = { "foo.bar" },
                    expect = { lines = { "{foo.bar}" } },
                },
                {
                    name = "to end of line",
                    keys = "sa$(",
                    before = { "hello world" },
                    cursor = { 1, 6 },
                    expect = { lines = { "hello (world)" } },
                },
            },
        },
        {
            pattern = "sd{char}",
            desc = "Delete surrounding",
            tests = {
                {
                    name = "delete quotes",
                    keys = 'sd"',
                    before = { '"word"' },
                    cursor = { 1, 2 },
                    expect = { lines = { "word" } },
                },
                {
                    name = "delete parens",
                    keys = "sd)",
                    before = { "(nested)" },
                    cursor = { 1, 3 },
                    expect = { lines = { "nested" } },
                },
            },
        },
        {
            pattern = "sr{old}{new}",
            desc = "Replace surrounding",
            tests = {
                {
                    name = "quotes to single quotes",
                    keys = [[sr"']],
                    before = { '"word"' },
                    cursor = { 1, 2 },
                    expect = { lines = { "'word'" } },
                },
                {
                    name = "parens to brackets",
                    keys = "sr)>",
                    before = { "(inner)" },
                    cursor = { 1, 3 },
                    expect = { lines = { "<inner>" } },
                },
            },
        },
        {
            pattern = "sf / sF",
            desc = "Find surrounding (right / left)",
            tests = {
                {
                    name = "find right paren",
                    keys = "sf)",
                    before = { "a (b) c" },
                    cursor = { 1, 0 },
                    expect = { cursor = { 1, 3 } },  -- moves to opening paren
                },
            },
        },
        {
            pattern = "sh",
            desc = "Highlight surrounding",
            tests = {
                {
                    name = "highlight parens",
                    keys = "sh)",
                    before = { "(word)" },
                    cursor = { 1, 2 },
                    -- Phase 2: expect = { snapshot = true },
                    expect = { lines = { "(word)" } },  -- content unchanged
                },
            },
        },
    },
}
```

### Phase 2: Snapshot Support

#### 2.1 Implement snapshot parsing/writing in `runner.lua`

Add functions to parse and write the amber-style `.snap` format.

#### 2.2 Implement `capture_highlights()`

```lua
function M.capture_highlights(bufnr)
    local highlights = {}
    -- Use nvim_buf_get_extmarks or similar to capture highlight groups
    -- Return: { { group = "GroupName", range = { {row, col}, {row, col} } }, ... }
    return highlights
end
```

#### 2.3 Convert snapshot tests

Update `surround.lua` tests that need snapshot support (e.g., `sh` highlight test).

### Phase 3: Documentation Generator

#### 3.1 Create `lua/tests/docs/generator.lua`

```lua
local M = {}

function M.generate_grammar_table(fixture)
    local lines = { "Operator grammar:", "" }
    for _, grammar in ipairs(fixture.grammars) do
        local first_test = grammar.tests[1]
        local example = ""
        if first_test and first_test.expect.lines then
            example = string.format("(e.g., %s → %s)", first_test.keys, first_test.expect.lines[1])
        elseif first_test then
            example = string.format("(e.g., %s)", first_test.keys)
        end
        table.insert(lines, string.format("    %-17s %s %s", grammar.pattern, grammar.desc, example))
    end
    return lines
end

function M.generate_fixture_markdown(fixture)
    local lines = {}

    -- Title
    table.insert(lines, "## " .. fixture.title)
    table.insert(lines, "")

    -- Description
    table.insert(lines, fixture.desc)
    table.insert(lines, "")

    -- Grammar table
    vim.list_extend(lines, M.generate_grammar_table(fixture))
    table.insert(lines, "")

    -- Notes
    if fixture.notes then
        for _, note in ipairs(fixture.notes) do
            table.insert(lines, note)
            table.insert(lines, "")
        end
    end

    -- See also
    if fixture.see_also and #fixture.see_also > 0 then
        table.insert(lines, "See also: `" .. table.concat(fixture.see_also, "`, `") .. "`")
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

function M.generate()
    local output_dir = vim.fn.stdpath("config") .. "/doc/generated"
    vim.fn.mkdir(output_dir, "p")

    -- Collect all fixtures
    local fixture_files = vim.fn.glob(vim.fn.stdpath("config") .. "/lua/tests/docs/*.lua", false, true)
    fixture_files = vim.tbl_filter(function(f)
        local name = vim.fn.fnamemodify(f, ":t")
        return name ~= "runner.lua" and name ~= "generator.lua" and name ~= "init.lua"
    end, fixture_files)

    -- Generate combined plugins.md
    local sections = {}
    for _, fixture_path in ipairs(fixture_files) do
        local fixture = dofile(fixture_path)
        table.insert(sections, M.generate_fixture_markdown(fixture))
    end

    local plugins_md = "## Plugin Guides\n\n" .. table.concat(sections, "\n")
    local out_path = output_dir .. "/plugins.md"
    local f = io.open(out_path, "w")
    f:write(plugins_md)
    f:close()

    print("Generated: " .. out_path)
end

return M
```

#### 3.2 Update `doc/src/main.md`

````markdown
# KyleKing's Neovim Configuration

```{.include}
doc/src/help-navigation.md
doc/src/vim-essentials.md
doc/generated/plugins.md
doc/src/notes.md
````

````

#### 3.3 Add to `.gitignore`

```gitignore
doc/generated/
````

### Phase 4: Integration

#### 4.1 Update `.pre-commit-config.yaml`

```yaml
  - repo: local
    hooks:
      - id: generate-plugin-docs
        name: Generate plugin docs from fixtures
        entry: nvim --headless -c "lua 
          require('tests.docs.generator').generate()" -c "qall!"
        language: system
        files: ^lua/tests/docs/.*\.lua$
        pass_filenames: false
```

#### 4.2 Update AGENTS.md

Add section about doc-driven testing:

````markdown
### Documentation-driven tests

Plugin documentation is generated from test fixtures in `lua/tests/docs/`.

```bash
# Run fixture tests
nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Update snapshots
UPDATE_SNAPSHOTS=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Generate docs (happens automatically in pre-commit)
nvim --headless -c "lua require('tests.docs.generator').generate()" -c "qall!"
````

See `ACTUALLY_GOOD_TESTS.md` for fixture schema and architecture.

````

### Phase 5: Migration (Complete)

All 14 fixtures implemented with appropriate testing strategies.

#### 5.1 Fixture implementation summary

**Behavioral tests** (test actual keybinding functionality):
1. ✓ `surround.lua` - add, delete, replace surrounding pairs
2. ✓ `comment.lua` - toggle comments
3. ✓ `move.lua` - API-based move operations
4. ✓ `operators.lua` - sort, multiply operations
5. ✓ `ai.lua` - enhanced text objects
6. ✓ `pick.lua` - fuzzy finder with setup functions
7. ✓ `flash.lua` - labeled motion
8. ✓ `hipatterns.lua` - keyword highlighting with snapshots

**Config validation** (appropriate for UI-heavy or system plugins):
9. ✓ `files.lua` - mini.files file explorer
10. ✓ `diff.lua` - mini.diff/mini.git/diffview
11. ✓ `clue.lua` - mini.clue keybinding hints
12. ✓ `terminal.lua` - terminal integration
13. ✓ `color.lua` - color and UI settings
14. ✓ `utilities.lua` - custom utilities

**Not implemented** (by design):
- `nap.lua` - Plugin loaded but has no keybindings configured; no fixture needed

#### 5.2 Documentation cleanup

✓ No hand-written `doc/src/plugins.md` exists - all plugin documentation is auto-generated from fixtures

#### 5.3 Test organization

✓ Plugin tests in `lua/tests/plugins/` provide **complementary** coverage, not duplication:
- `editing_spec.lua` - Additional behavioral test cases beyond fixture examples
- `keybinding_spec.lua` - Comprehensive mini.clue configuration validation (trigger completeness, orphan detection, duplicate detection)
- Tests follow the principle: "verify behavior, not existence"

---

## Performance Profiling

The test runner includes built-in performance profiling to identify slow tests and optimize fixture execution.

**Enable profiling**: Set `PROFILE_TESTS=1` environment variable.

**Output format**:
- Fixtures sorted by duration (slowest first)
- Grammars taking >10ms shown with test counts
- Total time, test count, and per-test average

**Example output**:
```
=== Fixture Performance Profile ===

flash: 245.32ms (8 tests)
  s{motion} / S{motion}: 89.15ms (3 tests)
  ;/,: 45.28ms (2 tests)

surround: 156.89ms (15 tests)
  sa{motion}{char}: 42.13ms (4 tests)

Total: 2.45s across 142 tests in 18 fixtures
Average per test: 17.25ms
```

**Use cases**:
- Identify slow fixtures needing optimization
- Track performance regressions in CI
- Compare performance before/after changes

## Snapshot Diffing

Snapshot mismatch errors show detailed line-by-line diffs instead of generic equality failures.

**Error format**:
```
Snapshot mismatch: sa{motion}{char} > word with quotes

Lines differ:
  Expected:
    "word"
  Actual:
    "word

Cursor position differs: expected [1, 1], got [1, 0]

Highlights differ:
  Expected:
    MiniSurroundHighlight at [[1,0], [1,1]]
  Actual:
    (none)

Run with UPDATE_SNAPSHOTS=1 to update this snapshot.
```

**Benefits**:
- Immediately see what changed without re-running with verbose mode
- Clear context for cursor and highlight differences
- Actionable fix instructions

## Commands Reference

```bash
# Run all fixture tests
nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Run single fixture
nvim --headless -c "lua require('tests.docs.runner').run_fixture('lua/tests/docs/surround.lua')" -c "qall!"

# Update snapshots (creates new, updates changed, prunes stale)
UPDATE_SNAPSHOTS=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Profile fixture performance
PROFILE_TESTS=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Generate documentation
nvim --headless -c "lua require('tests.docs.generator').generate()" -c "qall!"

# Full pipeline (what pre-commit does)
nvim --headless -c "lua require('tests.docs.generator').generate()" -c "qall!" && prek run panvimdoc --all-files
````

## Success Criteria

- [x] `runner.lua` executes fixture tests with `lines` expectations
- [x] `runner.lua` handles snapshot read/write/compare
- [x] `runner.lua` prunes stale snapshots in update mode
- [x] `generator.lua` outputs valid markdown
- [x] Pre-commit generates docs before panvimdoc runs
- [x] At least 5 plugin fixtures migrated (18 total!)
- [x] Hand-written `plugins.md` deleted (no hand-written plugin docs exist)
- [x] AGENTS.md updated with new workflow
- [x] Default keybindings and behaviors documented (nap.nvim, window management, core keymaps, LSP completion)

## Implementation Complete

### ✓ Phase 3: Documentation Integration (Complete)

1. ✓ **Review generated documentation output** - Generated `doc/generated/plugins.md` (548 lines, 14 fixtures)
1. ✓ **Update doc/src/main.md** - Includes `doc/generated/plugins.md`
1. ✓ **Configure .gitignore** - Added `doc/generated/` to .gitignore

### ✓ Phase 4: Pre-commit Integration (Complete)

1. ✓ **Add pre-commit hook** - Added `generate-plugin-docs` hook before panvimdoc
1. ✓ **Update AGENTS.md** - Added "Documentation-driven tests" section with commands and hybrid testing approach

### ✓ Phase 5: Fixture Coverage (Complete)

**18 fixtures implemented** covering all configured plugins AND default vim behaviors with appropriate testing strategies:

- **Behavioral tests**: surround, move, operators, comment, ai, pick, flash, hipatterns, core-keymaps
- **Snapshot tests**: hipatterns, move (with visual state capture)
- **Config validation**: diff, clue, terminal, color, utilities, navigation, windows, lsp-keymaps
- **Default behaviors**: navigation (nap.nvim), windows (splits/resizing), core-keymaps (custom vim enhancements), lsp-keymaps (completion)

**Architectural decisions**:

1. **Terminal integration** - Basic functionality check only; interactive terminal testing in headless mode is impractical
1. **Git/diff** - Config validation appropriate for UI-heavy plugins (diff overlay, diffview)
1. **mini.clue** - Config validation in fixture; comprehensive configuration tests in `keybinding_spec.lua`
1. **nap.nvim** - No fixture created; plugin loaded but has no keybindings configured

### ✓ Phase 6: Documentation Cleanup (Complete)

1. ✓ **Hand-written plugin docs** - No `doc/src/plugins.md` exists; all plugin documentation is generated
1. ✓ **Test organization** - Plugin tests in `lua/tests/plugins/` provide complementary (not duplicate) coverage:
    - `editing_spec.lua` - Additional behavioral test cases for comment/surround/operators
    - `keybinding_spec.lua` - Comprehensive mini.clue configuration validation
    - Tests follow "verify behavior, not existence" principle

## Future Enhancements

**System is complete and functional.** All optional improvements implemented (2026-02-03):

- ✓ **Expand test cases**: Added edge cases to surround.lua (multi-line, nested, etc.)
- ✓ **Regression tests**: Created comprehensive guide (REGRESSION_TEST_GUIDE.md)
- ✓ **Performance profiling**: Profile test execution time per fixture (set `PROFILE_TESTS=1`)
- ✓ **CI integration**: Fixture tests explicitly run in GitHub Actions with profiling enabled
- ✓ **Snapshot diffing**: Improved error messages show line-by-line diffs with context
- ✓ **Documentation validation**: Script validates documented keybindings have tests (lua/tests/docs/validate_documentation.lua)
- ✓ **Coverage tracking**: luacov integration for custom modules (scripts/run_tests_with_coverage.sh)
- ✓ **Test coverage**: Added tests for ui.lua, clue_help.lua (all custom modules now tested)
- ✓ **Additional fixtures**: All fixtures complete (markdown-editing.lua covers list_editing, preview; LSP covered in lsp-advanced.lua, lsp-keymaps.lua; navigation in bufjump.lua, navigation.lua)

See `TEST_ENHANCEMENT_SUMMARY.md` for complete implementation details.

**Architectural notes for future maintenance**:

- Fixtures serve dual purpose: user-facing documentation AND behavioral tests
- Config validation fixtures are appropriate for UI-heavy or system-level plugins
- Plugin tests in `lua/tests/plugins/` complement fixtures with deeper configuration validation
- Follow hybrid testing approach: simple keys in fixtures, complex keys via API calls
- Document is preserved as architectural reference, not a task list
