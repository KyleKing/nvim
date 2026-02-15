# Compositional Design Principles

## Core Concept

Vim's power comes from compositional grammar: `operator × text-object = action`. This creates combinatorial explosion: 10 operators × 20 text objects = 200 operations from 30 primitives.

**Key properties:**

- **Uniform interface** - Everything operates on the same abstraction (text buffers)
- **Repeatability** - Operations can be recorded and replayed
- **Extensibility** - Trivial to add new primitives without modifying existing ones
- **Determinism** - Same input always produces same output
- **Locality** - Users stay close to the data being manipulated

## Successful Implementations

**Unix pipes** - Composable text streams where each tool does one thing well **jq** - Composable data transformations with piping and filters **Git** - Composable version control commands with consistent flag patterns **SQL** - Composable queries (though verbose) **React hooks** - Composable UI state management

## Why Systems Resist Composition

**1. No uniform interface** - Vim operates on text buffers (universal). Infrastructure operates on: VMs, containers, databases, networks, APIs (no single abstraction).

**2. State management** - Vim operations are mostly stateless transformations. Infrastructure is inherently stateful with idempotency, rollback, and reconciliation concerns.

**3. Cultural inertia** - Industry converged on declarative configs (YAML/JSON). Composable architecture gaining traction but adoption is slow.

**4. Error handling complexity** - Vim: operation fails → buffer unchanged. Infrastructure: operation fails → partial state requiring cleanup.

**5. Mental model mismatch** - Vim: "modify this text in this way" (imperative). Infrastructure: "system should eventually be in this state" (declarative).

## Design Strategy

### Identify Your Primitives

**Operators** - What actions are truly atomic?

- Cloud: `new`, `attach`, `tag`, `monitor`, `scale`, `migrate`
- Data: `from`, `select`, `enrich`, `transform`, `aggregate`, `to`
- Config: `install`, `configure`, `enable`, `backup`

**Objects** - What are you operating on?

- Cloud: Resources selected by `tag:X`, `region:Y`, `type:Z`
- Data: Records selected by JSONPath, SQL predicates
- Config: Hosts selected by `env:prod`, `role:web`

**Composition rules** - How do operations chain?

- Output of one operation is input to next
- Operations are pure functions (no hidden side effects)
- Errors propagate explicitly

### Orthogonal API Design

Build primitives first, then compose. Avoid diagonal APIs that bundle multiple concerns.

```
# Orthogonal (good)
load(id) | process(transform) | save()

# Diagonal (avoid)
loadAndProcessAndSave(id, transform)
```

Each primitive should:

- Do one thing well
- Compose with all other primitives
- Have clear input/output contracts
- Handle errors at boundaries only

### Enable Repeatability

Operations should be:

- **Scriptable** - Can be saved and re-executed
- **Parametric** - Accept arguments/configuration
- **Inspectable** - Can view what will happen before execution
- **Reversible** - Support undo where possible

## Application Domains

### High Value (★★★★★)

**Cloud Infrastructure** - Current YAML/HCL configs are verbose and non-composable. Operators (`new`, `attach`, `scale`) + selectors (`tag:env=prod`) would enable script-based infrastructure.

**Data Pipelines** - Current DAG frameworks require excessive boilerplate. Composable operators (`from`, `select`, `transform`, `to`) would enable command-line data engineering.

**Configuration Management** - Ansible playbooks are declarative but verbose. Composable system operations (`install`, `configure`, `enable`) on host selectors would streamline automation.

### Medium Value (★★★☆☆)

**API Design** - REST is noun-based. Operator-based APIs with method chaining enable more expressive queries.

**Build Systems** - Most are declarative configs. Composable build operations (`compile`, `test`, `package`) would enable flexible pipelines.

### Low Value (★☆☆☆☆)

**TUIs** - Visual state is complex. VHS for demos + traditional tests work better than compositional commands.

**Interactive systems** - Ephemeral state resists pure functional composition.

## Implementation Checklist

- [ ] Define primitive operators for your domain
- [ ] Define objects/selectors operators act upon
- [ ] Create uniform interface (what's your "text buffer"?)
- [ ] Make operations chainable (output → input)
- [ ] Enable scripting/repeatability
- [ ] Provide escape hatches for imperative code
- [ ] Test composition boundaries (operator × object combinations)

## The Real Question

Not "can we make CLIs vim-like?" but "can we design systems where **composition is the primary abstraction**?"

The paradigm shift is designing with compositional primitives from the start, not retrofitting vim keybindings onto existing tools.
