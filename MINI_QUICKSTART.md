# Mini.nvim Quick Start Guide

This guide shows you how to use the 5 newly added mini.nvim modules with practical examples.

## 🎨 mini.hipatterns - Automatic Highlighting

Highlights patterns in your code automatically as you type!

### What it Highlights

1. **Hex Colors** - Shows colors visually
   ```lua
   -- Try typing these - they'll show in their actual colors!
   local red = "#ff0000"
   local blue = "#00f"
   local green = "#00ff00"
   ```

2. **TODO Keywords** - Highlights special comments
   ```lua
   -- TODO: Implement this feature
   -- FIXME: Bug in calculation
   -- HACK: Temporary workaround
   -- NOTE: Important information
   -- PERF: Performance consideration
   ```

### No Configuration Needed!

Just type and watch it work. Perfect for:
- CSS/HTML development (hex colors)
- Code review (spotting TODOs)
- Documentation (highlighting notes)

---

## 📐 mini.indentscope - Visual Indent Guides

Shows a visual line for your current indent scope - essential for Python, Lua, YAML!

### Text Objects

Work just like vim's built-in text objects:

```python
def my_function():
    if condition:
        # Cursor here - press 'vii' to select this indent block
        do_something()
        do_more()
    # Press 'vai' to select INCLUDING the borders
```

**Keymaps**:
- `ii` - Select inside indent scope (excludes borders)
- `ai` - Select around indent scope (includes borders)

**Examples**:
- `dii` - Delete everything at current indent level
- `vii` - Visual select current indent block
- `cii` - Change current indent block
- `yai` - Yank indent block with borders

### Navigation

Jump to indent scope boundaries:

```python
def outer():          # Press '[i' to jump here
    def inner():
        x = 1
        y = 2         # <- Cursor here
        z = 3
    return None       # Press ']i' to jump here
```

**Keymaps**:
- `[i` - Jump to top of current indent scope
- `]i` - Jump to bottom of current indent scope

### Visual Indicator

You'll see a `│` line on the left showing your current scope. It updates as you move!

---

## 💡 mini.cursorword - Auto-highlight Word

Automatically highlights all instances of the word under your cursor.

### How It Works

```lua
local function calculate_sum(items)
    local sum = 0  -- Move cursor to 'sum' here
    for _, value in ipairs(items) do
        sum = sum + value  -- All 'sum' instances light up!
    end
    return sum
end
```

### Benefits

- **Find all usages** instantly without searching
- **Refactoring helper** - see where variables are used
- **Reading code** - track variable usage visually
- **No keymaps** - just move your cursor!

### When It's Useful

- Reviewing function parameters
- Tracking variable assignments
- Spotting duplicated code
- Understanding data flow

---

## 🔧 mini.operators - Powerful Text Operations

Five text operators that work like vim's native operators (d, c, y).

### 1. Evaluate (`g=`) - Calculator in Your Editor

Evaluate math expressions and replace with result:

```lua
-- Type g=ip with cursor in these lines to evaluate:
2 + 2           -- Becomes: 4
10 * 5          -- Becomes: 50
math.sqrt(16)   -- Becomes: 4.0
```

**How to use**:
1. Type `g=` followed by a motion
2. Examples:
   - `g=ip` - Evaluate current paragraph
   - `g=iw` - Evaluate current word
   - `g=2j` - Evaluate next 2 lines

### 2. Exchange (`gx`) - Swap Text Regions

Swap two pieces of text easily:

```lua
-- Swap function arguments:
function foo(first, second)
--           ^^^^^  ^^^^^^
-- 1. Cursor on 'first', press gxiw
-- 2. Cursor on 'second', press gxiw (again)
-- Result: function foo(second, first)
```

**How to use**:
1. Mark first region: `gx{motion}` (e.g., `gxiw` for word)
2. Mark second region: `gx{motion}` (they swap!)

**Examples**:
- `gxiw` twice - Swap two words
- `gxip` twice - Swap two paragraphs
- `gx$` twice - Swap to end of line

### 3. Multiply (`gm`) - Duplicate Text

Duplicate text multiple times:

```lua
-- Type '3gmiw' on 'hello' to get:
hello
-- Becomes:
hellohellohello
```

**How to use**:
- `{count}gm{motion}` - Duplicate N times
- Examples:
  - `3gmiw` - Triple the word
  - `2gmip` - Duplicate paragraph twice
  - `5gm$` - Repeat to end of line 5 times

### 4. Replace (`gr`) - Paste Over

Replace text with register content:

```lua
-- 1. Yank "new_value": yiw
local x = new_value
-- 2. Replace "old_value": griw
local y = old_value
-- Result: local y = new_value
```

**How to use**:
1. Yank something first: `yiw`, `yap`, etc.
2. Use `gr{motion}` to replace:
   - `griw` - Replace word with register
   - `grip` - Replace paragraph
   - `gr$` - Replace to end of line

### 5. Sort (`gs`) - Sort Lines

Sort text alphabetically:

```python
# Cursor anywhere in these lines, press 'gsip':
zebra
apple
banana
# Becomes:
apple
banana
zebra
```

**How to use**:
- `gs{motion}` - Sort lines in motion
- Examples:
  - `gsip` - Sort paragraph lines
  - `gs2j` - Sort next 2 lines
  - In visual mode: `gs` to sort selection

---

## 💾 mini.sessions - Session Management

Save and restore your complete Neovim state (open files, window layout, etc.)

### Quick Start

**Save a session**:
```
<leader>Ss
> Session name: my-project█
```

**Restore a session**:
```
<leader>Sr
> Shows picker with all sessions
> Select one to restore
```

### Common Workflows

#### 1. Project-based Sessions

```
# Working on different projects:
:cd ~/projects/api-server
<leader>Ss  → "api-dev"

:cd ~/projects/frontend
<leader>Ss  → "frontend-dev"

# Later, quick switch:
<leader>Sr  → Select "api-dev"
```

#### 2. Feature Branches

```
# Different features = different sessions:
git checkout feature/auth
<leader>Ss  → "auth-feature"

git checkout feature/ui
<leader>Ss  → "ui-feature"

# Switch between features:
<leader>Sr  → Select session matching branch
```

#### 3. Local Project Sessions

```
# Save session in project directory (team-shareable!)
<leader>SW  → Saves to .nvim-session

# Add to .gitignore or commit for team
echo ".nvim-session" >> .gitignore
# OR
git add .nvim-session  # Share with team!

# Load local session
<leader>SL  → Loads .nvim-session from current dir
```

### All Session Keymaps

| Keymap | Action | Description |
|--------|--------|-------------|
| `<leader>Ss` | Save session | Prompts for name, saves to ~/.local/share/nvim/sessions/ |
| `<leader>Sr` | Restore session | Shows picker to select session |
| `<leader>Sd` | Delete session | Shows picker to delete session |
| `<leader>Sl` | Load latest | Loads most recent session |
| `<leader>Sw` | Write current | Saves to current session name |
| `<leader>SL` | Load local | Loads `.nvim-session` from current directory |
| `<leader>SW` | Write local | Saves `.nvim-session` to current directory |

### What Gets Saved

- All open buffers and files
- Window splits and layout
- Current working directory
- Cursor positions
- Marks and jumps
- Fold states

### What Doesn't Get Saved

- Terminal buffers (by design)
- Plugin state (most plugins)
- Undo history
- Registers

### Pro Tips

1. **Auto-save on exit**: Already configured! Sessions auto-save when you quit.

2. **Per-project sessions**: Use local sessions for project-specific setups:
   ```bash
   cd my-project
   nvim
   # Set up your windows/files
   <leader>SW  # Saves to my-project/.nvim-session
   ```

3. **Session workflow**:
   ```
   Morning:  <leader>Sl  # Resume yesterday's work
   End of day: Just :qa! # Auto-saves current session
   ```

4. **Clean start**: Launch without loading any session:
   ```bash
   nvim --clean
   # Or just don't load a session in Neovim
   ```

---

## 🎯 Real-World Examples

### Example 1: Python Development with Indent Scope

```python
def process_data(items):
    results = []
    for item in items:
        if item.valid:
            # Cursor here
            # - Press 'ii' to select just the if block
            # - Press 'ai' to include the if statement
            # - Press ']i' to jump to end of if block
            processed = transform(item)
            results.append(processed)
    return results
```

### Example 2: Refactoring with Operators

```javascript
// Exchange function arguments:
function createUser(name, email, age)  // Want: age, email, name
//                  ^^^^  ^^^^^  ^^^
// Solution: gxiw on 'name', gxiw on 'age' to swap
// Then: gxiw on 'name' (now in middle), gxiw on 'email'

// Calculate and replace:
const total = 25 * 4 + 10  // Want to see result
// Solution: g=$ to evaluate to end of line → const total = 110
```

### Example 3: Session for Full-stack Development

```bash
# Set up full-stack session:
cd my-app
nvim

# Open relevant files:
:e frontend/src/App.tsx
:vsplit backend/api/routes.go
:split docker-compose.yml

# Save this layout:
<leader>Ss → "fullstack-dev"

# Later, restore instantly:
<leader>Sr → Select "fullstack-dev"
# All files open, splits restored!
```

### Example 4: Color Theme Development

```css
/* With mini.hipatterns, see colors as you type: */
.primary { color: #3b82f6; }    /* See the blue! */
.success { color: #10b981; }    /* See the green! */
.danger { color: #ef4444; }     /* See the red! */

/* Sort color definitions: */
/* Cursor anywhere in these lines, press 'gsip': */
.warning { color: #f59e0b; }
.danger { color: #ef4444; }
.success { color: #10b981; }
/* Becomes alphabetically sorted! */
```

---

## 🚀 Next Steps

1. **Try each module** - Spend 5 minutes with each one
2. **Learn the keymaps** - Start with the most used ones
3. **Create a session** - Save your current workspace
4. **Use operators daily** - Especially `g=` and `gx`
5. **Watch the highlights** - Notice the automatic highlighting

These modules work together to make your editing faster and more visual!
