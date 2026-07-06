## Vim Essentials

A concise reference for the most commonly used Vim features. Each section
includes a `:h` cross-reference for deeper reading.

## Modes

    Normal          Default mode; navigate and compose commands
    Insert          Type text (enter with i, a, o, etc.)
    Visual          Select text (v char, V line, <C-v> block)
    Command-line    Enter commands (:, /, ?)
    Operator-pending Waiting for a motion after an operator (d, c, etc.)
    Terminal         Inside :terminal buffer

    <Esc>           Return to Normal mode from any mode
    <C-c>           Alternative escape (does not trigger InsertLeave)

See also: `vim-modes`, `mode-switching`

## Motions & Text Objects

Motions move the cursor. Text objects select regions.

Basic motions:

    h j k l         Left, down, up, right
    w / W           Next word / WORD start
    b / B           Previous word / WORD start
    e / E           End of word / WORD
    0 / ^           Start of line / first non-blank
    $               End of line
    gg / G          Start / end of file
    { / }           Previous / next blank line (paragraph)
    %               Matching bracket

Search motions:

    f{char}         Forward to char on current line
    t{char}         Forward to before char
    F{char}/T{char} Backward equivalents
    ;               Repeat last f/t forward
    ,               Repeat last f/t backward
    /{pattern}      Search forward
    ?{pattern}      Search backward
    n / N           Next / previous search match
    *               Search for word under cursor

Text objects (use after operator or in Visual mode):

    iw / aw         Inner / around word
    is / as         Inner / around sentence
    ip / ap         Inner / around paragraph
    i" / a"         Inner / around double quotes
    i( / a(         Inner / around parentheses
    i{ / a{         Inner / around braces
    it / at         Inner / around HTML/XML tag

See also: `motion.txt`, `text-objects`, `object-select`

## Operators

Operators act on motions or text objects: `{operator}{motion}`.

    d               Delete (cut)
    c               Change (delete + enter Insert)
    y               Yank (copy)
    >  /  <         Indent / dedent
    =               Auto-indent
    gU / gu         Uppercase / lowercase
    !               Filter through external program

Common combinations:

    dd / cc / yy    Operate on whole line
    D / C           Delete / change to end of line
    diw             Delete inner word
    ci"             Change inside double quotes
    yap             Yank around paragraph
    >ip             Indent paragraph
    gUiw            Uppercase inner word

The operator-motion grammar composes: any operator works with any motion
or text object. Learning them separately multiplies your capabilities.

See also: `operator`

## Registers

Registers are named storage slots for text. Every yank/delete uses one.

    ""              Default register (unnamed)
    "0              Last yank (not delete)
    "1 - "9         Delete history (most recent = "1)
    "a - "z         Named registers (you choose)
    "A - "Z         Append to named register
    "+              System clipboard
    "*              Primary selection (X11) / clipboard (macOS)
    "_              Black hole (discard)
    "/              Last search pattern
    ".              Last inserted text
    ":              Last command
    "%              Current filename

Usage:

    "ayy            Yank line into register a
    "ap             Paste from register a
    <C-r>a          Insert register a in Insert/Command mode
    :reg            Show all register contents

Recipes:

    "ayy ... "Ayy   Collect scattered lines: yank first into a, append rest with A
    "_dd            Delete without clobbering any register
    "0p             Paste the last yank after a delete overwrote ""
    :reg abc        Inspect only registers a, b, c

See also: `registers`, `:reg`

## Clipboard Workflow

This config keeps vim registers and the system clipboard separate
(`clipboard=unnamedplus` is intentionally NOT set). Plain `y`/`d`/`p` stay
fast and never touch other apps; leader-prefixed keys bridge to the OS.

    <leader>y       Yank to clipboard (normal or visual)
    <leader>Y       Yank line to clipboard
    <leader>p       Paste from clipboard
    <leader>P       Paste before from clipboard
    <C-v> (insert)  Paste clipboard while typing
    <leader>fr      Find registers (picker)

Recipe -- move misplaced Python imports to the top of the file:

    1. On the import line: Vj (extend selection over the block)
    2. d               Delete (default register; clipboard untouched)
    3. gg then P       Paste above the first line
    4. gv then <       Reselect pasted block, dedent (repeat < as needed)
    5. <C-o><C-o>      Jump back to where you were editing

For several scattered imports, delete each block with "Add (append to
register a with capital A after the first "add), then paste once at the
top with "ap.

Debugging clipboard issues:

    :let @+ = "test"        Write clipboard directly, paste in another app
    :checkhealth provider   Verify the clipboard provider is working

See also: `quoteplus`, `clipboard`

## Marks

Marks save cursor positions you can jump back to.

    m{a-z}          Set local mark (buffer-local)
    m{A-Z}          Set global mark (cross-file)
    '{mark}         Jump to mark (first non-blank)
    `{mark}         Jump to mark (exact column)

Automatic marks:

    ''              Position before last jump
    '.              Position of last change
    '^              Position of last insert
    '[  /  ']       Start / end of last change or yank
    '<  /  '>       Start / end of last visual selection

    :marks          List all marks
    :delmarks a-d   Delete marks a through d
    <leader>f'      Find marks (picker)

See also: `mark-motions`, `:marks`

## Jumplist & Changelist

Vim records where you have been (jumplist) and where you have edited
(changelist). Both are per-window/per-buffer histories you can walk.

    <C-o> / <C-i>   Older / newer position in jumplist
    g; / g,         Older / newer position in changelist
    gi              Insert mode at last insert position
    :jumps          Show the jumplist
    :changes        Show the changelist

Motions that add a jumplist entry: `G`, `gg`, `/`, `?`, `n`, `N`, `%`,
`{`, `}`, marks, and `:e`. Plain `j`/`k`/`w` do not.

This config adds bufjump.nvim to separate cross-file from in-file jumps:

    <leader>bn / <leader>bp     Jump forward/back to a different buffer
    <leader>bN / <leader>bP     Jump forward/back within this buffer

Recipe: after `gd` (or a search) takes you somewhere to read, `<C-o>`
returns you to the edit site. `g;` is often better: it goes to the last
change even if you never set a mark.

See also: `jump-motions`, `changelist`

## Macros

Record a sequence of commands, replay it any number of times.

    q{register}     Start recording into register
    q               Stop recording
    @{register}     Play back macro
    @@              Repeat last played macro
    {count}@{reg}   Play macro {count} times

Tips:

- Use `0` or `^` at the start to ensure consistent cursor position
- End with `j` to move to the next line for line-wise repetition
- `5@a` runs macro `a` five times
- Record with `qA` (capital) to append more keystrokes to macro `a`
- Edit a macro: `"ap` to paste, edit text, `"ayy` to re-yank

A macro is just text in a register, recorded as you edit one instance.
Make the recording position-independent (start with `0`, use `f`/`t`/`w`
instead of counting `l`), then replay it everywhere.

Recipe -- convert a list of names to function calls:

    Buffer:             Goal:
    alpha               check("alpha")
    beta                check("beta")

    qa                  Record into a
    0                   Normalize cursor position
    ciw check("<C-r>-") Wrap word (<C-r>- inserts what ciw deleted)
    <Esc>j              Back to normal, move down
    q                   Stop recording
    @a then @@          Replay on next line, repeat
    99@a                Or finish the whole list at once

Recipe -- apply a macro to matching lines only:

    :g/TODO/normal @a       Run macro a on every line containing TODO
    :'<,'>normal @a         Run macro a on each visually selected line

If a step fails (e.g. `f"` finds nothing), the macro stops on that line,
which is a feature: replay with a large count and it halts at the first
line that does not match the expected shape.

See also: `recording`, `@`, `q`

## Visual Mode

    v               Character-wise visual
    V               Line-wise visual
    <C-v>           Block-wise visual (column select)
    gv              Reselect last visual selection
    o               Move to other end of selection

In Visual mode, operators apply to the selection:

    d               Delete selection
    c               Change selection
    y               Yank selection
    >  /  <         Indent / dedent selection
    U / u           Uppercase / lowercase selection
    :               Enter command for selection (auto-fills range)
    I / A           Block insert / append (block mode)

This config adds:

    A (visual)      Select whole buffer

See also: `visual-mode`, `visual-operators`, `blockwise-visual`

## Quickfix & Location Lists

Quickfix is a global list of file locations. Location list is per-window.

    :copen / :lopen     Open quickfix / location list
    :cclose / :lclose   Close
    :cnext / :cprev     Next / previous entry
    :cfirst / :clast    First / last entry
    :cdo {cmd}          Run {cmd} on each quickfix entry

Populated by:

- `:grep` or `:vimgrep`
- LSP diagnostics (`<leader>cD` in this config)
- `:helpgrep`
- Many plugins (mini.pick sends to quickfix)

Picker:

    <leader>fl      Find in quickfix/location lists

Recipe -- project-wide rename without LSP:

    :grep old_name          Populate quickfix from ripgrep
    :cdo s/old_name/new_name/g | update

`:cdo` runs on every entry; `:cfdo` runs once per file (better for
`%s///` or formatting). `| update` writes each changed buffer.

This config adds a full quickfix suite under `<leader>q` (filter, dedupe,
stats, batch code actions, sessions). See the Diagnostics Workflows
section: `kyleking-neovim-diagnostics-workflows`.

See also: `quickfix`, `location-list`, `:cdo`, `:cfdo`

## Folds

This config uses treesitter-based folding with all folds open by default
(`foldlevel = 99`).

    za              Toggle fold under cursor
    zo / zc         Open / close fold
    zR / zM         Open / close all folds
    zr / zm         Reduce / increase fold level by one
    [z / ]z         Go to start / end of current fold

See also: `folding`, `fold-commands`

## Substitute & Global

    :[range]s/{pattern}/{replacement}/[flags]

Common flags:

    g               All occurrences on each line (not just first)
    c               Confirm each substitution
    i / I           Case insensitive / sensitive
    n               Count matches without replacing

Examples:

    :%s/foo/bar/g       Replace all "foo" with "bar" in file
    :'<,'>s/foo/bar/g   Replace in visual selection
    :s/\v(\w+)/\U\1/g  Uppercase all words on current line

The `:global` command runs Ex commands on matching lines:

    :g/{pattern}/{cmd}      Execute {cmd} on lines matching {pattern}
    :v/{pattern}/{cmd}      Execute on lines NOT matching
    :g/TODO/d               Delete all lines containing TODO
    :g/^$/d                 Delete all empty lines
    :g/pattern/normal @a    Run macro a on matching lines

See also: `:substitute`, `:global`, `sub-replace-special`

## The Dot Command

    .               Repeat the last change

The dot command replays the last edit. Structure your edits as
repeatable units: use text objects, avoid extra motions inside a change.

    ciw{new}<Esc>   Change word. Now n. repeats on next match.
    A;{Esc}         Append semicolon. Now j. repeats on next line.

The "dot formula": one keystroke to move, one keystroke to act.

    *               Search word under cursor (moves to next match)
    ciwnewname<Esc> Change it once
    n.n.n.          Review each match, dot to apply, n to skip

This is often better than `:%s//newname/g` because you approve each
change in context, and better than a macro for single-edit repetition.

See also: `single-repeat`

## Undo Tree

Vim tracks undo as a tree, not a linear stack. Branches form when you
undo then make a new edit.

    u               Undo
    <C-r>           Redo
    g-  /  g+       Go to older / newer text state (traverses branches)
    :earlier 5m     Go back 5 minutes
    :later 5m       Go forward 5 minutes
    :undolist       Show undo branches

This config highlights undo/redo changes with `highlight-undo.nvim`.

See also: `undo-tree`, `:earlier`, `:undolist`

## Practice Exercises

Self-checks that combine the topics above. Try each in a scratch buffer
before reading the answer.

1. On `x = "one" .. "two"` with the cursor at start of line, change
   `two` without moving the cursor first.

   Answer: `cin"` (mini.ai "change inside next quote"). Plain `ci"`
   would target `one`.

2. Delete a line without losing the text you yanked a moment ago.

   Answer: `"_dd` (black hole), or just `dd` and later paste the yank
   with `"0p`.

3. You changed a word deep in the file, then scrolled far away. Return
   to the edit and continue typing where you left off.

   Answer: `g;` jumps to the last change; `gi` re-enters insert at the
   last insert point directly.

4. Add a trailing comma to every line of a 40-line block.

   Answer: `V` select the block, then `:normal A,` (runs on each line).
   Macro alternative: `qa A,<Esc>j q` then `39@a`. Dot alternative:
   `A,<Esc>` then `j.` repeated.

5. Uppercase every occurrence of a variable name, one decision at a
   time.

   Answer: `*` on the word, `gUiw`, then `n.` for each match you want.

6. Delete every line in the file containing `DEBUG`.

   Answer: `:g/DEBUG/d`

7. Rename a symbol across all files that `:grep` finds, then write the
   changes.

   Answer: `:grep old_name` then `:cfdo %s/old_name/new_name/gc | update`

8. Record a macro that fails halfway through on one line. How do you
   fix the macro without re-recording it?

   Answer: paste it with `"ap`, edit the keystrokes as text, yank it
   back with `"ayy` (or `qA` to append missing keystrokes at the end).
