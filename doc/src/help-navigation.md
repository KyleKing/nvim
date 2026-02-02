## Navigating Help

Neovim's built-in help system is navigated with tags. Every `*word*` in help files defines a tag; every `|word|` links to one.

```
<C-]>         Follow the tag under the cursor
<C-t>         Jump back to previous location
<C-o>         Jump back (generic jumplist)
```

Useful help commands:

```
:h {topic}             Open help for a topic
:h key-notation        How keys are written (<CR>, <C-w>, etc.)
:helpgrep {pattern}    Search across all help files
:h index               Full index of all default key bindings
```

This config adds pickers for discovering bindings interactively:

```
<leader>fh     Find in nvim help (fuzzy search help tags)
<leader>fk     Find keymaps (all active keymaps, searchable)
```

Reading help syntax:

```
{arg}          Required argument
[arg]          Optional argument
|tag|          Clickable link to another help tag
CTRL-X         Hold Ctrl and press X (written <C-x> in mappings)
```

See also: `:help`, `key-notation`, `helpgrep`
