# Documentation-Driven Testing

## The Problem

Traditional documentation and tests diverge:

- **Documentation**: Written once, becomes stale, no guarantee of accuracy
- **Tests**: Verify behavior but don't explain usage
- **Examples**: Manually maintained, often broken

## The Solution

**Test fixtures as single source of truth** - Generate documentation from behavioral tests.

## Core Concept

```
Fixture (YAML/Code) → Tests (verify behavior) + Docs (explain usage)
                    ↓                          ↓
                [Guarantees correctness]  [Always accurate]
```

**Benefits:**

1. Documentation is always correct (it's literally running tests)
1. Examples show real usage patterns
1. Single maintenance point
1. Behavior changes automatically update docs

## Where This Works

### ★★★★★ CLI Tools with File I/O

**Fixture format:**

```yaml
test: Format Python file
input_files:
  main.py: |
    def   foo( ):
        pass
command: ruff format main.py
expect_files:
  main.py: |
    def foo():
        pass
```

**Generated docs:**

````markdown
### Format Python file

Before:

```python
def   foo( ):
    pass
```
````

After running `ruff format main.py`:

```python
def foo():
    pass
```

**Why it works:**

- Concise input/output
- File diffs are visual
- Minimal setup needed

### ★★★★☆ HTTP APIs

**Fixture format:**

```yaml
test: "Create user"
request:
  POST /api/users
  body: {"name": "Alice", "email": "alice@example.com"}
response:
  status: 201
  body: {"id": 1, "name": "Alice", "email": "alice@example.com"}
```

**Generated docs:**

````markdown
### Create user

**Request:**

```http
POST /api/users
Content-Type: application/json

{"name": "Alice", "email": "alice@example.com"}
```
````

**Response:**

```http
HTTP/1.1 201 Created

{"id": 1, "name": "Alice", "email": "alice@example.com"}
```

**Why it works:**

- Request/response pairs are natural documentation
- Tools like [go-httpdoc](https://github.com/mercari/go-httpdoc) already do this
- State setup is hidden in test harness

### ★★★☆☆ Pure Function Libraries

**Fixture format:**

```python
@doc_fixture
def parse_date():
    return [
        ("2026-01-15", "2026-01-15T00:00:00Z"),
        ("Jan 15, 2026", "2026-01-15T00:00:00Z"),
        ("15/01/2026", "2026-01-15T00:00:00Z"),
    ]
```

**Generated docs:**

```markdown
### parse_date

| Input          | Output                 |
| -------------- | ---------------------- |
| `2026-01-15`   | `2026-01-15T00:00:00Z` |
| `Jan 15, 2026` | `2026-01-15T00:00:00Z` |
| `15/01/2026`   | `2026-01-15T00:00:00Z` |
```

**Why it works:**

- Input/output is the entire API
- Minimal context needed
- Table format is scannable

### ★★☆☆☆ TUIs (with Command Abstraction)

**Fixture format:**

```yaml
test: Toggle watch and dispatch
before:
  selected_workflow: deploy.yml
  watch_enabled: false
  inputs:
    environment: staging
commands:
  - toggle_watch
  - set_input: {key: environment, value: production}
  - dispatch
after:
  watch_enabled: true
  inputs:
    environment: production
expect:
  command_run: gh workflow run deploy.yml -f environment=production
```

**Generated docs:**

````markdown
### Toggle watch and dispatch

**Actions:**

1. `toggle_watch` - Enable watch mode
2. `set_input environment=production` - Change deployment target
3. `dispatch` - Execute workflow

**Result:**

```bash
gh workflow run deploy.yml -f environment=production
```
````

**Why it's harder:**

- Requires command abstraction (not just key presses)
- State setup is verbose
- Visual feedback not captured

**Alternative:** Use VHS for visual demos, fixtures for behavior tests

### ★☆☆☆☆ Streaming/Interactive CLIs

**Why it fails:**

- Ephemeral state (scrolling, cursor position)
- Time-dependent behavior
- User perception vs machine state
- Better served by traditional tests + VHS demos

## Implementation Patterns

### Pattern 1: Fixture Files (vim approach)

**Structure:**

```lua
-- lua/tests/docs/plugin.lua
return {
    {
        name = "Toggle comment",
        before = { "function foo() {", "  return 42", "}" },
        cursor = { 2, 0 },
        keys = "gcc",
        expect = { lines = { "function foo() {", "  // return 42", "}" } },
    },
    -- More fixtures...
}
```

**Test harness:**

```lua
local fixtures = require("tests.docs.plugin")
for _, fx in ipairs(fixtures) do
    test(fx.name, function()
        local buf = create_buffer(fx.before)
        set_cursor(fx.cursor)
        feedkeys(fx.keys)
        assert_lines_equal(get_lines(buf), fx.expect.lines)
    end)
end
```

**Doc generator:**

```lua
for _, fx in ipairs(fixtures) do
    doc:write("### " .. fx.name)
    doc:write("Before: `" .. table.concat(fx.before, "\\n") .. "`")
    doc:write("Keys: `" .. fx.keys .. "`")
    doc:write("After: `" .. table.concat(fx.expect.lines, "\\n") .. "`")
end
```

**Advantages:**

- Fixtures are data (easy to modify)
- Single source for tests and docs
- Minimal boilerplate

**Disadvantages:**

- Limited to simple cases (complex setup needs code)
- Schema must be comprehensive
- Fixture parsing adds complexity

### Pattern 2: Annotated Tests (Python doctest)

**Structure:**

```python
def parse_date(s: str) -> datetime:
    """Parse various date formats.

    >>> parse_date("2026-01-15")
    datetime(2026, 1, 15)

    >>> parse_date("Jan 15, 2026")
    datetime(2026, 1, 15)
    """
    # Implementation...
```

**Test harness:** Built into Python (`python -m doctest`)

**Doc generator:** Built into Sphinx/mkdocs

**Advantages:**

- Tests live in docstrings (colocated)
- No separate fixture files
- Standard tooling

**Disadvantages:**

- Limited to simple examples
- Hard to test complex setup
- Pollutes function signatures

### Pattern 3: Command-Based (TUI approach)

**Structure:**

```go
// Command abstraction
type Command interface {
    Execute(m Model) (Model, error)
    String() string
}

// Fixtures reference commands
type Fixture struct {
    Before   State
    Commands []Command
    After    State
}
```

**Test harness:**

```go
for _, fx := range fixtures {
    m := modelFromState(fx.Before)
    for _, cmd := range fx.Commands {
        m, _ = cmd.Execute(m)
    }
    assert.Equal(t, fx.After, m.ToState())
}
```

**Doc generator:**

```go
for _, fx := range fixtures {
    fmt.Printf("**Actions:**\n")
    for _, cmd := range fx.Commands {
        fmt.Printf("- `%s`\n", cmd.String())
    }
}
```

**Advantages:**

- Commands are first-class values
- Testable without UI
- Composable, replayable

**Disadvantages:**

- Requires architectural refactor
- More complex than key handlers
- Need to maintain command → key mapping

## Design Guidelines

### When to Use Fixtures

**Good candidates:**

- Pure functions with simple I/O
- CLI tools with deterministic output
- APIs with request/response patterns
- Domain logic with clear inputs/outputs

**Poor candidates:**

- UI-heavy interactions
- Async/streaming operations
- Time-dependent behavior
- Complex state setup (>20 lines)

### Fixture Schema Design

**Minimize verbosity:**

```yaml
# Bad: too much boilerplate
test:
  name: "Example"
  description: "Long explanation"
  metadata:
    author: "Kyle"
    date: "2026-01-15"
  setup:
    files: {...}
    env: {...}
  # ... 50 more lines

# Good: essential only
test: "Example"
input: "data"
output: "result"
```

**Prefer composition:**

```yaml
# Bad: duplicate setup
test1: {setup: {'...': null}, input: a, output: b}
test2: {setup: {'...': null}, input: c, output: d}

# Good: shared context
setup_default: &setup
  files: {'...': null}

tests:
  - {<<: *setup, input: a, output: b}
  - {<<: *setup, input: c, output: d}
```

**Handle special cases:**

```yaml
# Complex setup needs code
setup:
  fn: "generate_large_dataset"  # Reference to helper function
  args: { rows: 1000 }

# Simple cases inline
setup:
  files:
    input.txt: "hello world"
```

## Documentation Generation

### Markdown Output

**Table format** for function examples:

```markdown
| Input          | Output           |
| -------------- | ---------------- |
| `"2026-01-15"` | `"Jan 15, 2026"` |
```

**Code blocks** for CLI examples:

````markdown
```bash
$ mytool format input.py
Formatted 1 file
```
````

**Diffs** for transformation tools:

````markdown
Before:

```python
def   foo( ):
    pass
```

After:

```python
def foo():
    pass
```
````

### Interactive Documentation

**Jupyter-style** for data transformations:

```python
# Input
df = load_data("users.csv")

# Transform
df_active = df[df.active == True]

# Output
print(df_active.head())
#    id  name     active
# 0   1  Alice    True
# 2   3  Charlie  True
```

**Runnable examples** via literate testing:

```markdown
## Example: Filter users

<!-- fixture:filter_users -->
```

Where `<!-- fixture:filter_users -->` triggers:

1. Extract fixture data
1. Run test to verify
1. Inject output into docs

## Tradeoffs

### Advantages

**Guaranteed accuracy:**

- Examples are executed on every test run
- Broken examples break CI
- No stale documentation

**Single maintenance point:**

- Change fixture → tests and docs update
- Refactor code → fixtures fail → update once

**Comprehensive coverage:**

- Document edge cases (they're in tests)
- Show error handling (failure fixtures)

### Disadvantages

**Upfront complexity:**

- Need fixture schema
- Need doc generator
- Need test harness integration

**Verbosity for complex cases:**

- Setup/teardown code
- Mock dependencies
- State management

**Limited expressiveness:**

- Hard to explain "why" in fixtures
- Prose explanations still needed
- Architectural docs separate

## Hybrid Approach

**Use fixtures for:**

- API examples (request/response)
- CLI usage (input/output)
- Pure functions (argument/return)

**Use prose for:**

- Architecture explanations
- Design decisions
- Troubleshooting guides
- Conceptual overviews

**Use VHS/screenshots for:**

- TUI interactions
- Visual workflows
- Interactive demos

## Success Metrics

A documentation-driven testing approach succeeds when:

1. **Developers update fixtures, not docs** - Fixtures are the natural place to document
1. **Examples never break** - CI catches stale examples immediately
1. **Coverage increases** - More test cases = more documentation
1. **Onboarding improves** - New users learn from accurate examples

## Resources

- [Python doctest](https://docs.python.org/3/library/doctest.html) - Tests embedded in documentation
- [phmdoctest](https://github.com/tmarktaylor/phmdoctest) - Test markdown code blocks
- [go-httpdoc](https://github.com/mercari/go-httpdoc) - Generate API docs from tests
- [LiterAPI](https://github.com/agnoster/literapi) - Markdown with API examples as tests
- [VHS](https://github.com/charmbracelet/vhs) - Generate terminal demos from scripts
