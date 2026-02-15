# Composable System Design

## The Vim Paradigm

Vim's power derives not from keybindings but from **compositional grammar**:

```
operator × text-object = action
d        × iw          = delete inner word
c        × i"          = change inside quotes
```

**Key properties:**

- **Combinatorial explosion**: 10 operators × 20 text objects = 200 operations from 30 primitives
- **Uniform interface**: Everything operates on text buffers
- **Repeatability**: `.` command, macros, replay
- **Extensibility**: Trivial to add new primitives
- **Determinism**: Same input → same output
- **Locality**: Direct manipulation of data

## Where This Works Today

**Unix pipes** - Composable text streams:

```bash
cat logs.txt | grep ERROR | cut -d' ' -f3 | sort | uniq -c
```

**jq** - Composable data transformations:

```bash
jq '.items[] | select(.active) | .name'
```

**SQL** - Composable queries:

```sql
SELECT name FROM users WHERE active AND created > '2026-01-01'
```

**React hooks** - Composable UI state:

```javascript
const [data, loading] = useAsync(fetchUser);
const filtered = useFilter(data, criteria);
```

## Where It's Needed

### Infrastructure (Terraform/CloudFormation)

**Current**: 50+ lines of YAML/HCL boilerplate per resource

**Composable approach**:

```bash
# Operators: new, attach, tag, monitor, scale
# Selectors: tag:X, region:Y, type:Z (like text objects)
infra new ec2 t2.micro ami-12345 | \
    attach sg:web:80,443 | \
    tag env=prod | \
    deploy us-east-1a

# Apply to selections
infra select tag:env=prod | monitor cpu,mem,disk
```

### Data Pipelines (Airflow/Dagster)

**Current**: DAG frameworks with boilerplate setup/teardown

**Composable approach**:

```bash
# Operators: from, select, enrich, transform, aggregate, to
data from s3://raw/users.json | \
    select .active == true | \
    enrich with postgres://db/profiles on .user_id | \
    transform normalize_dates | \
    aggregate by .country | \
    to clickhouse://analytics/user_stats
```

### Configuration Management (Ansible)

**Current**: YAML playbooks with state/handlers/templates

**Composable approach**:

```bash
# Operators work on host selectors
sys on hosts:web | install nginx:latest | configure from ./nginx.conf
sys on env:prod region:us-east | update kernel
sys on tag:database | backup /var/lib/mysql to s3://backups
```

### Build Systems

**Current**: Declarative configs (Make, npm scripts, gradle) without composition

**Composable approach**:

```bash
# Chainable build pipeline
build source src/*.go | test unit | lint golangci | compile -o bin/app

# Selectors work like text objects
build changed-since main | test affected | compile
build tag:api | test integration | deploy staging
```

## Why Systems Resist Composability

**1. No universal interface**

- Vim operates on text buffers (universal)
- Infrastructure operates on: VMs, containers, databases, networks (heterogeneous)
- Need abstraction layer that preserves composability

**2. State management complexity**

- Vim operations are mostly stateless (transform text)
- Infrastructure is stateful (created resources persist)
- Requires idempotency, rollback, reconciliation

**3. Cultural inertia**

- Industry converged on declarative configs (YAML/JSON)
- People understand nouns (resources) better than verbs (operators)
- Imperative composition seems "less safe" than declarative configs

**4. Error propagation**

- Vim: operation fails → buffer unchanged
- Infrastructure: operation fails → partial state, cleanup needed
- Composable systems need sophisticated error handling

## Design Principles for Composable Systems

**1. Identify your "text objects"** What are you operating on?

- Infrastructure: resources, hosts, regions
- Data: rows, fields, aggregations
- Build: files, tests, artifacts

**2. Define orthogonal operators** What actions are primitive vs composite?

- Create primitives first (low-level operations)
- Build composites from primitives (convenience)
- Example: `loadAndProcessAndSave(id)` is bad; `load(id) | process | save` is good

**3. Make operations chainable** Output of one is input to next:

- Use consistent data types (streams, collections, resources)
- Preserve metadata through pipeline
- Enable lazy evaluation where possible

**4. Enable repeatability** Commands should be scriptable:

- Serialize operations as data
- Support record/replay
- Provide transaction/rollback

**5. Provide escape hatches** Composition doesn't preclude imperative code:

- Allow inline code blocks for complex logic
- Support custom operators
- Enable debugging/inspection at each step

## Success Criteria

A system is compositional when:

1. **Primitives are small** - Each does one thing well
1. **Interfaces are uniform** - Output of one fits input of next
1. **Combinations are predictable** - No special cases or gotchas
1. **Extensions are natural** - Adding new operators/objects is trivial
1. **Errors are local** - Failures don't corrupt entire pipeline

## Anti-Patterns

**Diagonal APIs** - Functions that combine orthogonal concerns:

```python
# Bad: combines loading, filtering, transforming, saving
process_and_save_users(filter_active=True, normalize=True, output="db")

# Good: separate concerns
load_users() | filter(active=True) | normalize() | save_to("db")
```

**Hidden state** - Operations that depend on implicit context:

```python
# Bad: depends on global state
set_environment("production")
deploy()  # Implicitly uses environment

# Good: explicit context
deploy(environment="production")
```

**Non-chainable outputs** - Operations that can't compose:

```python
# Bad: returns None, can't chain
save_to_database(data)

# Good: returns data, enables chaining
save_to_database(data)  # Returns data for next stage
```

## Where to Apply This

**High value:**

- CLI tools with file I/O (formatters, linters, converters)
- Data transformation libraries (parsers, validators)
- HTTP APIs (method chaining, query builders)
- Infrastructure automation (kill YAML verbosity)

**Medium value:**

- Build systems (replace declarative configs)
- Configuration management (replace playbooks)
- System administration (composable sys ops)

**Low value:**

- Interactive TUIs (state is too complex)
- Stateful services (databases, caches)
- Real-time systems (composition adds latency)

## Resources

- [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) - Rule of Modularity, Rule of Composition
- [Small, Sharp Tools](https://brandur.org/small-sharp-tools) - Composable minimalism
- [Composable Architecture: 2026 Tipping Point](https://www.infojiniconsulting.com/blog/composable-data-architectures-explained-why-2026-is-the-tipping-point/) - Industry trend toward modularity
- [Tile-Based Programming Primitives](https://www.emergentmind.com/topics/tile-based-programming-primitives) - GPU/AI kernel composition
- [Solid.js Primitives](https://primitives.solidjs.community/) - "Each primitive designed with composition in mind"
