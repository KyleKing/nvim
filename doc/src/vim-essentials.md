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

This config maps:

    <leader>ry      Yank to * register
    <leader>rp      Paste from * register
    <leader>rY      Yank to + register
    <leader>rP      Paste from + register
    <leader>fr      Find registers (picker)

See also: `registers`, `:reg`

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
- Edit a macro: `"ap` to paste, edit text, `"ayy` to re-yank

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

See also: `quickfix`, `location-list`, `:cdo`

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
