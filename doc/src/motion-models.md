## Choosing a Motion

This config layers several targeting tools on top of Vim's operator
grammar. This section is a decision guide for which to reach for.

Quick reference:

    ci" daw yap     Known target near cursor: plain text objects
    cin" dil(       Next/last variant when cursor is outside the target
    d]m y]z         Structural motion: treesitter next method/fold/class
    d<A-s>{chars}   Distant visible target: flash jump as operator target
    <A-S> then d    Explore first: flash treesitter selects a syntax node
    daf dac         Semantic object: mini.ai function call / class

## When to Use Each

Plain text objects (`i`/`a` + object) when you are inside or on the
target: `ci"`, `daw`, `yap`, `gUiw`. Fastest, and `.`-repeatable.

Next/last text objects (mini.ai) when the target is visible but the
cursor is not in it: `cin"` (change inside next quote), `dil(` (delete
inside last paren). Saves a motion.

Flash jump (`<A-s>`) when the target is far but visible: type a couple
of characters, pick the label. Composes with operators, so `d<A-s>`
deletes from cursor to the labeled position.

Flash treesitter (`<A-S>`) when you want Helix-style select-then-act:
labels appear on syntax nodes (expression, block, function), you pick
one to select it, then apply `d`/`c`/`y`. Best when you are not sure of
the exact text object name.

Treesitter motions (`]m`, `[m`, etc. via nap.nvim and textobjects) for
moving between structural units, and as operator targets: `d]m` deletes
to the next method start.

Replacing incremental selection: the classic treesitter
`incremental_selection` (`<C-space>` to grow the selection node-by-node)
was dropped with the move to nvim-treesitter `main`. For its two uses,
reach for flash treesitter (`<A-S>`) to label and pick any syntax node,
or mini.ai structural objects (`vam` a function, `vac` a class, `va?` a
conditional, `vao` a loop, `vak` a block) which are `.`-repeatable and
take next/last via `n`/`l` (for example `vanm` selects the next
function). Together these cover node selection without a dedicated
grow/shrink mode, and free `<C-space>`/`<C-s>`/`<M-,>`.

## Background: Two Motion Models

Helix/Kakoune use select-then-act: every operation starts from a visible
selection. Vim uses action-target: operators compose with any motion or
text object, which enables `.` repeat and two-keystroke edits but gives
no preview of what will change.

This config keeps Vim's model as the foundation (composability, dot
repeat, muscle memory) and adds the main benefit of the Helix model
through flash treesitter (`<A-S>`): visual confirmation of the selection
before acting, for the cases where you would otherwise guess at a text
object.

See also: `MiniAi`, `flash.nvim`, `text-objects`
