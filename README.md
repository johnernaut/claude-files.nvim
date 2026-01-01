# claude-files.nvim

A Neovim plugin to view and navigate files modified by [Claude Code CLI](https://claude.ai/claude-code).

## Features

- **View Changed Files** - See all files Claude Code modified in the current session
- **Quick Navigation** - Jump to files by number or Enter key
- **Dismiss Files** - Remove reviewed files from the list (they reappear if Claude modifies them again)
- **Per-project Tracking** - Dismissed files are remembered per project
- **Cross-platform** - Works on Linux and macOS

## Requirements

- Neovim >= 0.8.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [Claude Code CLI](https://claude.ai/claude-code) installed and used in your projects

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "johnernaut/claude-files.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local cf = require("claude-files")
    cf.setup()

    vim.keymap.set("n", "<leader>cc", cf.toggle, { desc = "Claude changed files" })
  end,
}
```

### Local Development

```lua
{
  dir = "~/code/claude-files.nvim",
  name = "claude-files",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local cf = require("claude-files")
    cf.setup()

    vim.keymap.set("n", "<leader>cc", cf.toggle, { desc = "Claude changed files" })
  end,
}
```

## Usage

### Important: Working Directory

**Open Neovim from the same directory where you ran Claude Code.**

```bash
cd ~/myproject
nvim .
```

### Open the File List

Press `<leader>cc` (or your configured keybinding) to see files Claude has changed.

### Popup Keybindings

| Key | Action |
|-----|--------|
| `<CR>` | Open file under cursor |
| `1-9` | Open file by number |
| `d` | Dismiss file (remove from list) |
| `<C-v>` | Open in vertical split |
| `<C-x>` | Open in horizontal split |
| `q` / `<Esc>` | Close popup |

### Dismissed Files

When you dismiss a file with `d`, it's removed from the list. If Claude modifies that file again in a future session, it will reappear automatically.

## Configuration

```lua
require("claude-files").setup({
  -- Where to save dismissed files data
  data_path = vim.fn.stdpath("data") .. "/claude-files.json",

  -- Auto-save when dismissing files
  save_on_change = true,

  -- Popup window settings
  menu = {
    width = 60,
    height = 10,
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  },
})
```

## API

```lua
local cf = require("claude-files")

cf.setup(opts)   -- Initialize with options
cf.toggle()      -- Toggle the changed files popup
cf.refresh()     -- Refresh data from disk
cf.save()        -- Save current state to disk
```

## How It Works

Claude Code CLI stores session data in `~/.claude/projects/`. Each project directory contains JSONL files with session history, including `file-history-snapshot` entries that track which files were modified.

This plugin:
1. Reads Claude Code's session files for the current project
2. Parses file modification history from JSONL
3. Shows changed files (minus any you've dismissed)
4. Re-shows dismissed files if Claude modifies them again

## Data Storage

- **Claude Code data**: `~/.claude/projects/{encoded-project-path}/`
- **Dismissed files**: `~/.local/share/nvim/claude-files.json`

## License

MIT
