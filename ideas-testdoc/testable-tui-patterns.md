# Testable TUI Patterns

## The TUI Testing Problem

TUIs (Terminal User Interfaces) are difficult to test because:

1. **Complex state** - Focus, scroll, modals, async updates, viewport
1. **Key press coupling** - Logic tied to keyboard handlers
1. **Visual output** - Terminal rendering is the primary interface
1. **Time dependencies** - Animations, polling, async operations

Traditional approaches:

- **VHS** - Records visual output but doesn't test behavior
- **Unit tests** - Test individual components but miss integration
- **Manual testing** - Catches bugs but doesn't prevent regression

## Solution: Command-Based Architecture

Separate **semantic actions** from **input handlers** and **visual rendering**.

```
Input (keys) → Command → Model Update → View Render
     ↓            ↓            ↓             ↓
  Ephemeral   Testable    Serializable   Visual
```

## Pattern 1: Command Abstraction

### Before (coupled to input)

```go
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        switch msg.String() {
        case "w":
            m.watchEnabled = !m.watchEnabled
            return m, nil
        case "enter":
            if m.selectedWorkflow >= 0 {
                return m, m.dispatchWorkflow()
            }
        }
    }
    return m, nil
}
```

**Problems:**

- Logic tied to key presses
- Can't test without simulating keyboard
- Can't replay commands
- Hard to document

### After (command-based)

```go
// Commands are first-class values
type Command interface {
    Execute(m Model) (Model, tea.Cmd, error)
    String() string  // For logging, replay, documentation
}

type ToggleWatchCmd struct{}
func (c ToggleWatchCmd) Execute(m Model) (Model, tea.Cmd, error) {
    m.watchEnabled = !m.watchEnabled
    return m, nil, nil
}
func (c ToggleWatchCmd) String() string { return "toggle_watch" }

type DispatchWorkflowCmd struct {
    WorkflowID string
}
func (c DispatchWorkflowCmd) Execute(m Model) (Model, tea.Cmd, error) {
    if m.selectedWorkflow < 0 {
        return m, nil, errors.New("no workflow selected")
    }
    return m, m.dispatchWorkflow(), nil
}
func (c DispatchWorkflowCmd) String() string {
    return fmt.Sprintf("dispatch %s", c.WorkflowID)
}

// Update now maps inputs to commands
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        cmd := m.keyToCommand(msg)
        if cmd != nil {
            var err error
            m, tcmd, err := cmd.Execute(m)
            if err != nil {
                m.error = err
            }
            return m, tcmd
        }
    case Command:
        // Direct command execution (for testing)
        return msg.Execute(m)
    }
    return m, nil
}

func (m Model) keyToCommand(key tea.KeyMsg) Command {
    switch key.String() {
    case "w": return ToggleWatchCmd{}
    case "enter": return DispatchWorkflowCmd{WorkflowID: m.selectedWorkflowID()}
    }
    return nil
}
```

**Benefits:**

- Commands are testable without keyboard
- Commands are replayable (record/redo)
- Commands are documentable (`.String()` method)
- Commands can be invoked programmatically

## Pattern 2: Serializable State

### Before (monolithic model)

```go
type Model struct {
    // Ephemeral UI state mixed with app state
    workflows        []workflow.File
    selectedWorkflow int
    selectedInput    int
    focused          Pane
    inputs           map[string]string
    watchEnabled     bool
    viewport         viewport.Model
    scrollOffset     int
    windowWidth      int
    windowHeight     int
    modal            modal.Model
    // ... 30+ more fields
}
```

**Problems:**

- Can't serialize entire state
- Hard to snapshot for tests
- Mixed concerns (app logic + UI rendering)

### After (separated state)

```go
// App state (serializable, testable)
type AppState struct {
    SelectedWorkflow string            `json:"selected_workflow"`
    SelectedBranch   string            `json:"selected_branch"`
    Inputs           map[string]string `json:"inputs"`
    WatchEnabled     bool              `json:"watch_enabled"`
    FocusedPane      string            `json:"focused_pane"`
}

// UI state (ephemeral, not tested)
type UIState struct {
    Viewport     viewport.Model
    WindowSize   tea.WindowSizeMsg
    ScrollOffset int
    Modal        modal.Model
}

// Model combines both
type Model struct {
    App       AppState
    UI        UIState
    workflows []workflow.File  // Reference data
}

// Serialization helpers
func (m Model) ToState() AppState {
    return m.App
}

func (m Model) FromState(s AppState) Model {
    m.App = s
    return m
}
```

**Benefits:**

- AppState is JSON-serializable
- Can snapshot for tests
- Clear boundary between app logic and UI

## Pattern 3: Fixture-Based Testing

### Fixture Format

```go
type Fixture struct {
    Name     string
    Before   AppState
    Commands []Command
    After    AppState
    Expect   ExpectedOutcome
}

type ExpectedOutcome struct {
    CommandRun string   // CLI command generated
    Error      string   // Expected error message
    Files      []string // Files created/modified
}
```

### Test Harness

```go
func TestFixtures(t *testing.T) {
    fixtures := []Fixture{
        {
            Name: "Toggle watch and dispatch",
            Before: AppState{
                SelectedWorkflow: "deploy.yml",
                WatchEnabled:     false,
                Inputs: map[string]string{
                    "environment": "staging",
                },
            },
            Commands: []Command{
                ToggleWatchCmd{},
                SetInputCmd{Key: "environment", Value: "production"},
                DispatchWorkflowCmd{WorkflowID: "deploy.yml"},
            },
            After: AppState{
                SelectedWorkflow: "deploy.yml",
                WatchEnabled:     true,
                Inputs: map[string]string{
                    "environment": "production",
                },
            },
            Expect: ExpectedOutcome{
                CommandRun: "gh workflow run deploy.yml -f environment=production",
            },
        },
    }

    for _, fx := range fixtures {
        t.Run(fx.Name, func(t *testing.T) {
            m := testModel().FromState(fx.Before)

            for _, cmd := range fx.Commands {
                var err error
                m, _, err = cmd.Execute(m)
                if fx.Expect.Error != "" {
                    assert.EqualError(t, err, fx.Expect.Error)
                    return
                }
                assert.NoError(t, err)
            }

            actual := m.ToState()
            assert.Equal(t, fx.After, actual)

            if fx.Expect.CommandRun != "" {
                assert.Equal(t, fx.Expect.CommandRun, m.lastCommand)
            }
        })
    }
}
```

### Documentation Generator

````go
func GenerateDocsFromFixtures(fixtures []Fixture) string {
    var out strings.Builder

    for _, fx := range fixtures {
        out.WriteString(fmt.Sprintf("### %s\n\n", fx.Name))

        // Show command sequence
        out.WriteString("**Actions:**\n")
        for i, cmd := range fx.Commands {
            out.WriteString(fmt.Sprintf("%d. `%s`\n", i+1, cmd.String()))
        }
        out.WriteString("\n")

        // Show state changes
        changes := diffStates(fx.Before, fx.After)
        if len(changes) > 0 {
            out.WriteString("**Changes:**\n")
            for _, change := range changes {
                out.WriteString(fmt.Sprintf("- %s: `%v` → `%v`\n",
                    change.Field, change.Before, change.After))
            }
            out.WriteString("\n")
        }

        // Show expected outcome
        if fx.Expect.CommandRun != "" {
            out.WriteString("**Result:**\n```bash\n")
            out.WriteString(fx.Expect.CommandRun)
            out.WriteString("\n```\n\n")
        }
    }

    return out.String()
}
````

**Generated documentation:**

````markdown
### Toggle watch and dispatch

**Actions:**

1. `toggle_watch`
2. `set_input environment=production`
3. `dispatch deploy.yml`

**Changes:**

- watch_enabled: `false` → `true`
- inputs.environment: `staging` → `production`

**Result:**

```bash
gh workflow run deploy.yml -f environment=production
```
````

## Pattern 4: Command Mode (Vim-Style)

Add a command palette for power users:

```go
type CommandMode struct {
    active bool
    input  textinput.Model
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    if m.commandMode.active {
        return m.handleCommandMode(msg)
    }

    switch msg := msg.(type) {
    case tea.KeyMsg:
        if msg.String() == ":" {
            m.commandMode.active = true
            return m, nil
        }
    }
    return m, nil
}

func (m Model) handleCommandMode(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch msg := msg.(type) {
    case tea.KeyMsg:
        if msg.Type == tea.KeyEnter {
            cmd := parseCommand(m.commandMode.input.Value())
            m.commandMode.active = false
            return cmd.Execute(m)
        }
        if msg.Type == tea.KeyEsc {
            m.commandMode.active = false
            return m, nil
        }
    }

    var cmd tea.Cmd
    m.commandMode.input, cmd = m.commandMode.input.Update(msg)
    return m, cmd
}

func parseCommand(s string) Command {
    parts := strings.Fields(s)
    switch parts[0] {
    case "dispatch":
        return DispatchWorkflowCmd{WorkflowID: parts[1]}
    case "set":
        kv := strings.SplitN(parts[1], "=", 2)
        return SetInputCmd{Key: kv[0], Value: kv[1]}
    case "toggle-watch", "watch":
        return ToggleWatchCmd{}
    }
    return nil
}
```

**User experience:**

```
:dispatch deploy.yml              # Dispatch by name
:set environment=production       # Set input
:watch                            # Toggle watch
:chain deploy-all                 # Execute chain
```

**Benefits:**

- Discoverable (`:help` command)
- Scriptable (save commands to file)
- Testable (commands are strings)
- Composable (chain with `&&`)

## Pattern 5: Modal Interaction (Optional)

For complex TUIs, consider vim-style modes:

```go
type Mode int
const (
    NormalMode Mode = iota  // Navigate, select
    CommandMode             // : prefix commands
    VisualMode              // Select multiple items
    InsertMode              // Edit inputs
)

type Model struct {
    mode Mode
    // ... rest of state
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch m.mode {
    case NormalMode:
        return m.handleNormal(msg)
    case CommandMode:
        return m.handleCommand(msg)
    case VisualMode:
        return m.handleVisual(msg)
    case InsertMode:
        return m.handleInsert(msg)
    }
    return m, nil
}
```

**Mode transitions:**

- Normal → Command: Press `:`
- Normal → Visual: Press `v`
- Normal → Insert: Press `i` or edit input
- Any → Normal: Press `Esc`

**Benefits:**

- Context-aware keybindings
- Reduced cognitive load (fewer simultaneous keys)
- Familiar to vim users

**Drawbacks:**

- Higher learning curve
- More complex state management
- Not always necessary (single-focus UIs don't need modes)

## Implementation Checklist

**Phase 1: Commands**

- [ ] Define Command interface
- [ ] Refactor key handlers to use commands
- [ ] Add command logging

**Phase 2: State**

- [ ] Extract AppState from Model
- [ ] Implement ToState/FromState
- [ ] Ensure AppState is serializable

**Phase 3: Testing**

- [ ] Create fixture format
- [ ] Write test harness
- [ ] Convert existing tests to fixtures

**Phase 4: Documentation**

- [ ] Build doc generator
- [ ] Generate markdown from fixtures
- [ ] Integrate into CI

**Phase 5: Advanced (optional)**

- [ ] Add command mode (`:` prefix)
- [ ] Implement macro recording
- [ ] Add modal interaction

## When to Use These Patterns

**Use command abstraction when:**

- Application has >10 keyboard shortcuts
- Need undo/redo functionality
- Want to test behavior without UI
- Building scriptable interfaces

**Use serializable state when:**

- State persistence is needed
- Want snapshot testing
- Complex state transitions
- Multi-user or session management

**Use fixtures when:**

- Documenting common workflows
- Integration testing
- Regression prevention
- Onboarding examples

**Use command mode when:**

- Power users are primary audience
- Many operations available
- Scripting/automation is valuable

**Use modal interaction when:**

- Context-dependent operations
- Large keybinding space
- Users familiar with vim/emacs

## Case Study: gh-lazydispatch

**Before:**

- 30+ keyboard shortcuts (hard to remember)
- State scattered across Model
- Tests coupled to key simulation
- No workflow documentation

**After (with patterns):**

- Commands: `ToggleWatch`, `SetInput`, `Dispatch`, etc.
- AppState: Serializable snapshot of user choices
- Fixtures: 10-15 common workflows documented + tested
- Command mode: `:dispatch`, `:set`, `:watch`

**Impact:**

- Test coverage: 60% → 85%
- Documentation: Manual → auto-generated
- User requests: "How do I X?" answered by fixtures
- Debugging: Command log shows exact user actions

## Resources

- [Elm Architecture](https://guide.elm-lang.org/architecture/) - Model-Update-View pattern
- [Bubble Tea](https://github.com/charmbracelet/bubbletea) - Go TUI framework
- [catwalk](https://github.com/knz/catwalk) - Data-driven Bubble Tea tests
- [teatest](https://github.com/charmbracelet/teatest) - Bubble Tea testing library
- [VHS](https://github.com/charmbracelet/vhs) - Terminal demo recorder (complements behavioral tests)
