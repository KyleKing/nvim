# Markdown WYSIWYG and editable preview

Status: proposal, not started. Written 2026-07-25.

## Problem

Long markdown from AI is read-heavy. Reviewing it as raw source means parsing `#`, `|`, `-`, and link syntax while trying to follow the argument, and a rendered view reads faster. Two separate wants fall out of that:

1. In-buffer rendering so headings, tables, lists, and code blocks display formatted while the file on disk stays plain markdown. This covers the read-heavy case and needs no browser.
1. Editing from the rendered view so a typo or a reworded sentence can be fixed where I am reading, without switching back to raw source. This is the harder want and nothing in the ecosystem does it the way I first pictured it.

The current setup (`lua/kyleking/utils/preview.lua`) is a one-way pipeline: pandoc renders the saved file to an HTML fragment, `wrap_html` drops it into `preview_template.html`, the result lands at `stdpath("cache")/kyleking-preview.html`, and `open`/`osascript` shows or reloads it. No server, no socket, and the HTML carries no line mapping back to source, so a browser edit has nowhere to go. There is no in-buffer renderer at all today, only the `conceallevel` toggle at `lua/kyleking/core/keymaps.lua:85`.

## What exists upstream

Checked 2026-07-25.

| Tool                          | Direction                                           | Fit                                              |
| ----------------------------- | --------------------------------------------------- | ------------------------------------------------ |
| render-markdown.nvim          | in-buffer, read + edit source                       | strong for want 1                                |
| markview.nvim                 | in-buffer, more formats                             | want 1, hybrid mode drops preview on cursor move |
| iamcco/markdown-preview.nvim  | buffer to browser only                              | preview only                                     |
| smp.nvim                      | "Edit in Neovim" is a file-open link, not text sync | not want 2                                       |
| GhostText (+ ghost-text.nvim) | browser textarea edited from nvim                   | backwards: nvim is still the typing surface      |
| Obsidian / HedgeDoc           | app owns the file                                   | real editor, but leaves nvim for that doc        |

No plugin lets me edit rendered text in a browser and sync it back to the buffer. smp.nvim advertises bidirectional but its README shows "Edit in Neovim" only opens a different file. GhostText syncs both ways but the wrong way round for this, keeping nvim as the editor for a browser textarea.

## Options

### A. In-buffer renderer only (render-markdown.nvim)

Draws formatting with extmarks, persistently across modes, anti-conceal unmasking only the cursor line. File stays plain markdown, so editing is normal buffer editing on rendered-looking text. Solves want 1 fully and collapses most of want 2, because the browser trip mostly disappears when the buffer already reads as formatted.

Cost: one plugin in `deps/syntax.lua`, a fixture under `lua/tests/docs/`. Low risk, reversible. Does not give a true WYSIWYG surface (no rendered tables you type into cell by cell), and wide GFM tables, embedded images, and print still want the browser preview.

### B. markview.nvim instead of A

Covers Typst, LaTeX, and Asciidoc too, more hackable. Hybrid mode drops the preview as the cursor moves, which breaks writing flow (flagged in the render-vs-markview Discourse thread). Better if the multi-format support matters; worse for straight prose editing.

### C. Extend the existing preview into an editable round-trip

Keep the browser but make it write back. Rough shape:

- a pandoc (or djot) Lua filter stamps `data-line` / `data-sourcepos` on block elements during render
- the template body becomes `contenteditable`
- an in-page converter turns edited HTML back into the source format (Turndown for markdown, or render straight from djot)
- a small local server (the piece the current design lacks) receives a per-block patch and applies it to the buffer by source line

Cost: a real build, a few hundred lines, and the hard part is HTML-to-source round-tripping. A whole-document convert-back reformats blocks I never touched, so it has to diff and splice only the changed block using the `data-line` anchor. Highest effort, highest payoff, and it is the only option that literally satisfies want 2.

### D. Hand the file to an app that already edits rendered markdown

Point Obsidian at the notes directory, or run HedgeDoc. Real WYSIWYG editing for free. Give up nvim for that document and accept a second tool in the loop. Reasonable for sustained note work, poor for a quick fix mid-review.

## Rendering engine and source format

Rendering does not constrain the source format. `djot-fmt` converts markdown to djot for most cases, so either can be the on-disk format and the other can be a render step. That gives three usable engine paths:

- pandoc GFM to HTML, which the current preview already does for markdown
- the djot CLI to HTML, which the current preview already does for djot (`djot_to_html`)
- markdown-it (mdit) if a JS-side renderer is wanted, most relevant under option C where the page already runs JS

For option C, djot is the more tractable back-conversion target than markdown, because its grammar is smaller and less ambiguous, so HTML-to-djot round-trips cleaner than HTML-to-markdown. If C is ever built, rendering djot and converting edits back to djot (with `djot-fmt` normalizing markdown inputs up front) avoids most of the Turndown normalization pain.

## Recommendation

Do A now: add render-markdown.nvim, keep the browser preview read-only for tables, images, and print. It is cheap, reversible, and removes most of the pain that prompted this. Hold B, C, and D as documented alternatives. Reconsider C only if, after living with A, editing rendered content in place is still a real gap, and prefer the djot render-and-back path if so.

## Open questions

- After A lands, does the want-2 gap survive, or does rendered-in-buffer editing close it in practice
- If C is pursued, is the source format migrated to djot, or does markdown stay canonical with `djot-fmt` as a render-time step
- Whether the local server for C is worth standing up only for preview, or waits until something else in the config wants one
