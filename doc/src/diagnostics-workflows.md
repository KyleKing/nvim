## Diagnostics Workflows

Project-wide type checking and linting with quickfix batch operations.
Keymap tables live in the Workspace Diagnostics plugin guide; this
section covers end-to-end workflows.

## Running Checkers

`<leader>lw{ecosystem}{tool}` runs a project-local tool (`.venv/bin/`,
`node_modules/.bin/`) across every project under the VCS root and sends
results to quickfix. `<leader>lwi` previews what projects are detected;
`<leader>lwd` collects LSP diagnostics from open buffers instead.

    <leader>lwpm / lwpp / lwpr / lwpt   Python: mypy / pyright / ruff / ty
    <leader>lwte / lwto                 TS/JS: eslint / oxlint
    <leader>lwgg                        Go: golangci-lint
    <leader>lwll                        Lua: selene

## Reviewing Results

    <leader>qs      Stats (count, by-file, by-type)
    <leader>qd      Dedupe entries
    <leader>qS      Sort by file + line
    <leader>qf      Filter: keep regex matches (e.g. error.*type, src/api/)
    <leader>qF      Filter: remove matches (e.g. test_.*\.py)
    <leader>qt      Filter by severity (interactive menu)
    <leader>fl      Picker, flat view (preview with context)
    <leader>qg      Picker, grouped by file
    <leader>qo/qO   Open all affected files (edit / vsplit)

## Fixing: Three Batch Modes

All three apply LSP code actions to quickfix items.

Auto (`<leader>qb`): one confirmation, applies the first matching action
to every item. Use for bulk trusted fixes; filter first with `<leader>qf`
or `<leader>qt`. Undo is per-buffer with `u`.

Interactive (`<leader>qB`): reviews each fix with
Apply | Skip | Apply to all remaining | Cancel. After the same action
type is applied twice, "Apply to all remaining" auto-applies the rest of
that pattern. Use when learning what a tool suggests or for mixed error
types.

Navigate (`<leader>qn`): opens every affected buffer, jumps to the first
item, and shows an instruction window. Move with `]q`/`[q`, fix at the
cursor with `<leader>ca`, and optionally batch-apply the remainder when
confident. Use for changes that need surrounding context.

## Example: Monorepo Type-Check Sweep

    <leader>lwi     15 Python projects, 4 Node projects detected
    <leader>lwpm    mypy across all Python projects
    <leader>qs      Total: 147 | Files: 23 | Errors: 89 | Warnings: 58
    <leader>qt      Keep errors only
    <leader>qB      Review fixes; "Apply to all remaining" on repeats

## Sessions

    <leader>qw      Save quickfix list to a file (e.g. .qf_mypy)
    <leader>qr      Load a saved list

Useful for resuming a large cleanup the next day, or comparing results
across runs.

Developer documentation (Lua API, custom code-action filters, adding new
tools) is in `doc/workspace-diagnostics.md` in the repo.

See also: `quickfix`, `:cdo`, `diagnostic`
