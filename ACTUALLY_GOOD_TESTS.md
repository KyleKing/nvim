# Documentation-Driven Testing Plan

## Problem

Documentation and tests are maintained separately, leading to drift. Documentation claims `saiw"` wraps a word in quotes, but nothing validates this remains true.

## Solution

Single-source fixtures that generate both:

1. **Behavioral tests** (mini.test) that verify functionality
1. **Documentation** (markdown → vimdoc) that describes functionality

## Progress

**Status**: Phase 1 and Phase 2 complete. 10 fixtures implemented with 32 passing test cases.

**Completed fixtures**:

- ✓ `surround.lua` - mini.surround (add, delete, replace, find, highlight)
- ✓ `move.lua` - mini.move (API-based tests for move operations)
- ✓ `operators.lua` - mini.operators (sort, multiply)
- ✓ `ai.lua` - mini.ai enhanced text objects
- ✓ `comment.lua` - mini.comment toggle functionality
- ✓ `hipatterns.lua` - mini.hipatterns keyword highlighting (with snapshots)
- ✓ `pick.lua` - mini.pick fuzzy finder
- ✓ `files.lua` - mini.files file explorer
- ✓ `diff.lua` - mini.diff git integration
- ✓ `flash.lua` - flash.nvim labeled motion

**Infrastructure enhancements**:

- runner.lua handles optional test fields (before, keys, cursor)
- save_snapshots safely handles nil values
- Hybrid testing approach: API calls for complex keybindings, config validation for UI-heavy plugins

**Generated artifacts**:

- 2 snapshot files (surround.snap, hipatterns.snap)
- Auto-generated documentation for all fixtures via generator.lua

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

### Phase 5: Migration

**Status**: 10 of 12 fixtures completed. Remaining: git.lua (comprehensive), terminal.lua, clue.lua, nap.lua

#### 5.1 Create fixtures for existing plugin docs

Priority order (by documentation complexity):

1. ✓ `surround.lua` - simple grammar table
2. ✓ `comment.lua` - simple grammar table
3. ✓ `move.lua` - simple grammar table (API-based)
4. ✓ `operators.lua` - mini.operators (sort, multiply)
5. ✓ `ai.lua` - mini.ai text objects
6. ✓ `pick.lua` - complex, needs setup functions
7. ✓ `files.lua` - mini.files
8. ✓ `diff.lua` - mini.diff (config validation)
9. [ ] `git.lua` - mini.git, diffview (comprehensive git workflow)
10. [ ] `terminal.lua` - terminal integration
11. [ ] `clue.lua` - mini.clue which-key hints
12. ✓ `flash.lua` - flash.nvim motion
13. [ ] `nap.lua` - nap.nvim navigation

#### 5.2 Remove redundant hand-written docs

Once fixtures exist, remove corresponding sections from `doc/src/plugins.md` (or delete the file entirely if fully generated).

#### 5.3 Delete superseded test files

After migration, these test files become redundant:

- `lua/tests/plugins/editing_spec.lua` → covered by fixtures
- `lua/tests/plugins/mini_ai_spec.lua` → covered by fixtures
- Other plugin behavior tests that duplicate fixture coverage

---

## Commands Reference

```bash
# Run all fixture tests
nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

# Run single fixture
nvim --headless -c "lua require('tests.docs.runner').run_fixture('lua/tests/docs/surround.lua')" -c "qall!"

# Update snapshots (creates new, updates changed, prunes stale)
UPDATE_SNAPSHOTS=1 nvim --headless -c "lua MiniTest.run_file('lua/tests/docs/runner_spec.lua')" -c "qall!"

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
- [x] At least 5 plugin fixtures migrated (10 total)
- [ ] Hand-written `plugins.md` deleted or minimal
- [x] AGENTS.md updated with new workflow

## Next Steps

### ✓ Phase 3: Documentation Integration (Complete)

1. ✓ **Review generated documentation output** - Generated `doc/generated/plugins.md` with 10 fixtures
1. ✓ **Update doc/src/main.md** - Now includes `doc/generated/plugins.md` instead of hand-written `doc/src/plugins.md`
1. ✓ **Configure .gitignore** - Added `doc/generated/` to .gitignore

### ✓ Phase 4: Pre-commit Integration (Complete)

1. ✓ **Add pre-commit hook** - Added `generate-plugin-docs` hook before panvimdoc
1. ✓ **Update AGENTS.md** - Added "Documentation-driven tests" section with commands and hybrid testing approach

### Phase 5: Expand Test Coverage

**Additional fixtures to consider**:

- `mini.git` - Git integration beyond diff
- `mini.clue` - Which-key style hints
- `nap.nvim` - Advanced navigation
- `bufjump.nvim` - Buffer jumping
- LSP keybinding tests (go to definition, hover, etc.)
- Custom utilities (noqa, list_editing, preview)

**Edge case testing**:

- Add more test cases to existing fixtures
- Test error paths and edge cases
- Add regression tests for discovered bugs

### Phase 6: Cleanup

1. **Review redundant tests**

    - Identify tests in `lua/tests/plugins/` that duplicate fixture coverage
    - Evaluate `lua/tests/plugins/editing_spec.lua` for migration/deletion
    - Evaluate `lua/tests/plugins/mini_ai_spec.lua` for migration/deletion

1. **Simplify hand-written docs**

    - Remove sections from `doc/src/plugins.md` covered by fixtures
    - Keep only non-fixture-based documentation (workflows, concepts)

### Optional Enhancements

- **Performance**: Profile test execution time per fixture
- **CI Integration**: Add fixture tests to GitHub Actions
- **Documentation validation**: Ensure all documented keybindings have corresponding tests
- **Snapshot diffing**: Better error messages showing what changed in snapshots
- **LLM Guidance**: delete this document and condense into a test-specific LLM guide on writing actually good tests
