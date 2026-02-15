# Design Patterns: Composability and Testability

This collection explores vim's compositional paradigm and documentation-driven testing, with practical patterns for building testable, composable systems.

## Documents

### [Composable System Design](composable-system-design.md)

**The vim paradigm applied to infrastructure, data pipelines, and APIs.**

Key insights:

- Operators × Objects = Combinatorial explosion of functionality
- Where composability succeeds (Unix, jq, SQL) and where it's needed (Terraform, Airflow, Ansible)
- Design principles: Identify primitives, enable chaining, maintain uniform interfaces
- Anti-patterns: Diagonal APIs, hidden state, non-chainable outputs

Best for: Architects designing CLI tools, infrastructure automation, or data transformation systems.

### [Documentation-Driven Testing](documentation-driven-testing.md)

**Generate documentation from test fixtures - single source of truth.**

Key insights:

- Fixtures as both tests and documentation
- Domain suitability: ★★★★★ CLIs with file I/O, ★★★★☆ HTTP APIs, ★★☆☆☆ TUIs
- Three implementation patterns: Fixture files (vim), Annotated tests (doctest), Command-based (TUI)
- Hybrid approach: Fixtures for examples, prose for architecture, VHS for visual demos

Best for: Library authors, CLI tool builders, API developers wanting guaranteed-accurate examples.

### [Testable TUI Patterns](testable-tui-patterns.md)

**Command-based architecture for testable, documentable terminal UIs.**

Key insights:

- Separate semantic actions (commands) from input handlers (keys) and rendering (view)
- AppState (serializable, testable) vs UIState (ephemeral)
- Fixture-based testing with generated documentation
- Command mode (`:dispatch`, `:set`) for power users
- Modal interaction (Normal/Insert/Visual) for complex applications

Best for: TUI developers using Bubble Tea or similar frameworks, wanting better testability.

## Core Concepts

### Composability

**Problem:** Most systems use monolithic operations or declarative configs that don't compose.

**Solution:** Design with small, orthogonal primitives that chain together.

**Example:**

```bash
# Instead of: terraform apply -var="env=prod" -var="region=us-east" config.tf
# Composable: infra select env:prod region:us-east | apply config
```

**When to apply:** CLIs, APIs, infrastructure automation, data pipelines.

### Documentation-Driven Testing

**Problem:** Documentation becomes stale; tests don't explain usage.

**Solution:** Test fixtures that generate both behavioral tests and user-facing docs.

**Example:**

```yaml
# Fixture (single source)
test: Format Python file
input: 'def   foo( ): pass'
output: "def foo():\n    pass"
# Generates:
# 1. Test that verifies formatting
# 2. Docs showing before/after
```

**When to apply:** Libraries with clear I/O, CLIs, HTTP APIs.

### Command Abstraction

**Problem:** TUI logic coupled to keyboard handlers; hard to test, document, replay.

**Solution:** Commands as first-class values with Execute(), String(), Undo().

**Example:**

```go
// Instead of: case "w": m.watch = !m.watch
// Command: ToggleWatchCmd{}.Execute(m)

// Benefits:
// - Testable without keyboard simulation
// - Logged for debugging
// - Replayed for testing
// - Documented automatically
```

**When to apply:** TUIs with >10 shortcuts, scriptable interfaces, undo/redo needs.

## Decision Matrix

### Should I use composable design?

| Domain            | Composability Value | Notes                            |
| ----------------- | ------------------- | -------------------------------- |
| CLI tools         | ★★★★★               | Natural fit; pipe to other tools |
| Infrastructure    | ★★★★★               | Kill YAML verbosity              |
| Data pipelines    | ★★★★★               | Replace DAG frameworks           |
| HTTP APIs         | ★★★☆☆               | Good for query builders          |
| TUIs              | ★★☆☆☆               | Complex state resists            |
| Stateful services | ★☆☆☆☆               | State management conflicts       |

### Should I use documentation-driven testing?

| Domain          | DDT Value | Recommended Approach                 |
| --------------- | --------- | ------------------------------------ |
| Pure functions  | ★★★★★     | Fixture files or doctest             |
| CLI file I/O    | ★★★★★     | YAML fixtures with file diffs        |
| HTTP APIs       | ★★★★☆     | Request/response fixtures            |
| TUIs            | ★★☆☆☆     | Command fixtures (requires refactor) |
| Streaming/async | ★☆☆☆☆     | Use VHS demos instead                |

### Should I use command abstraction?

| Scenario               | Value | Alternative          |
| ---------------------- | ----- | -------------------- |
| >10 keyboard shortcuts | ★★★★★ | Direct key handlers  |
| Need undo/redo         | ★★★★★ | Event sourcing       |
| Scriptable interface   | ★★★★★ | Separate CLI mode    |
| Testing without UI     | ★★★★☆ | Mock keyboard input  |
| Simple CRUD forms      | ★☆☆☆☆ | Traditional handlers |

## Implementation Priority

### Quick Wins (1-2 days)

1. **Extract commands** (TUI) - Decouple logic from keys
1. **Add fixtures** (Library/CLI) - Start with 3-5 common examples
1. **Generate docs** (Any) - Build simple fixture → markdown generator

### Medium Effort (1 week)

1. **Refactor for composability** - Split monolithic operations
1. **Separate AppState** (TUI) - Serializable vs ephemeral state
1. **Command mode** (TUI) - `:` prefix for power users

### Long-term (2-4 weeks)

1. **Modal interaction** (TUI) - Normal/Insert/Visual modes
1. **Macro recording** (TUI) - Record/replay command sequences
1. **Full composable rewrite** (Infrastructure) - New tool architecture

## Anti-Patterns to Avoid

**Over-engineering:**

- Don't add composability to simple scripts
- Don't create fixtures for trivial functions
- Don't add command mode to 5-button UIs

**Under-documenting:**

- Fixtures without prose explanations
- Generated docs with no context
- Command names without descriptions

**State leakage:**

- AppState containing UI-specific data
- Commands that modify global state
- Non-serializable dependencies

**Premature abstraction:**

- Creating operators before understanding domain
- Building command framework for 3 operations
- Generic fixtures instead of specific examples

## Success Metrics

**Composability:**

- New features built by combining existing primitives
- User requests for compositions, not new operations
- Reduced code: More capability, fewer lines

**Documentation-driven testing:**

- Fixtures updated more often than prose docs
- Zero stale examples in documentation
- User issues cite fixture numbers

**Command abstraction:**

- Debugging uses command logs, not "I pressed keys"
- Users request new commands, not new shortcuts
- Scripting/automation emerges organically

## Further Reading

**Composability:**

- [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy)
- [Small, Sharp Tools](https://brandur.org/small-sharp-tools)
- [Composable Architecture: 2026](https://www.infojiniconsulting.com/blog/composable-data-architectures-explained-why-2026-is-the-tipping-point/)

**Testing:**

- [Python doctest](https://docs.python.org/3/library/doctest.html)
- [go-httpdoc](https://github.com/mercari/go-httpdoc)
- [LiterAPI](https://github.com/agnoster/literapi)

**TUI Patterns:**

- [Elm Architecture](https://guide.elm-lang.org/architecture/)
- [Bubble Tea](https://github.com/charmbracelet/bubbletea)
- [catwalk](https://github.com/knz/catwalk)
- [VHS](https://github.com/charmbracelet/vhs)
