local M = {}

local popup = require("plenary.popup")
local utils = require("claude-files.utils")
local claude = require("claude-files.claude")
local marks = require("claude-files.marks")

local win_id = nil
local bufnr = nil
local current_files = {} -- Store current file list for keybinding access

--- Get the main module
---@return table
local function get_main()
  return require("claude-files")
end

--- Close the popup window
local function close_popup()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
  end
  win_id = nil
  bufnr = nil
  current_files = {}
end

--- Get files to display (changed files minus dismissed)
---@return { filename: string, time: string }[]
local function get_visible_files()
  local changed_files = claude.get_changed_files()
  local visible = {}

  for _, f in ipairs(changed_files) do
    if marks.should_show_file(f.filename, f.time) then
      table.insert(visible, f)
    end
  end

  return visible
end

--- Create and show the popup window
local function create_popup()
  local config = get_main().config

  -- Get files to display
  current_files = get_visible_files()

  if #current_files == 0 then
    vim.notify("No files changed by Claude Code (or all dismissed)", vim.log.levels.INFO)
    return
  end

  -- Format lines
  local lines = {}
  for i, f in ipairs(current_files) do
    local time_str = utils.relative_time(f.time)
    local padding = string.rep(" ", math.max(1, 45 - #f.filename))
    table.insert(lines, string.format("%d. %s%s%s", i, f.filename, padding, time_str))
  end

  -- Calculate dimensions
  local width = config.menu.width
  local height = math.min(config.menu.height, math.max(#lines, 1))

  -- Create buffer
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Create popup window
  win_id = popup.create(bufnr, {
    title = " Claude Changed Files ",
    line = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = config.menu.borderchars,
    padding = { 0, 1, 0, 1 },
  })

  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "claude-files")
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Set up keymaps
  setup_keymaps()
end

--- Set up keymaps for the popup buffer
function setup_keymaps()
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- Close popup
  vim.keymap.set("n", "q", close_popup, opts)
  vim.keymap.set("n", "<Esc>", close_popup, opts)

  -- Open file under cursor
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if current_files[line] then
      close_popup()
      marks.nav_to_file(current_files[line].filename)
    end
  end, opts)

  -- Open in vertical split
  vim.keymap.set("n", "<C-v>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if current_files[line] then
      local filepath = current_files[line].filename
      local cwd = utils.get_cwd()
      if not filepath:match("^/") then
        filepath = cwd .. "/" .. filepath
      end
      close_popup()
      vim.cmd("vsplit " .. vim.fn.fnameescape(filepath))
    end
  end, opts)

  -- Open in horizontal split
  vim.keymap.set("n", "<C-x>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if current_files[line] then
      local filepath = current_files[line].filename
      local cwd = utils.get_cwd()
      if not filepath:match("^/") then
        filepath = cwd .. "/" .. filepath
      end
      close_popup()
      vim.cmd("split " .. vim.fn.fnameescape(filepath))
    end
  end, opts)

  -- Dismiss file (remove from list)
  vim.keymap.set("n", "d", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if current_files[line] then
      marks.dismiss_file(current_files[line].filename)
      -- Refresh the popup
      close_popup()
      create_popup()
    end
  end, opts)

  -- Quick navigation with number keys
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      if current_files[i] then
        close_popup()
        marks.nav_to_file(current_files[i].filename)
      end
    end, opts)
  end
end

--- Toggle the changed files popup
function M.toggle()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    close_popup()
    return
  end

  create_popup()
end

return M
