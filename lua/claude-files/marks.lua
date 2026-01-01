local M = {}

local utils = require("claude-files.utils")

--- Get the main module (lazy loaded to avoid circular dependency)
---@return table
local function get_main()
  return require("claude-files")
end

--- Get dismissed files for the current project
---@return table<string, string> filename -> dismissed_time
function M.get_dismissed_files()
  local project = get_main().get_project_data()
  return project.dismissed or {}
end

--- Set dismissed files for the current project
---@param dismissed table<string, string>
function M.set_dismissed_files(dismissed)
  local project = get_main().get_project_data()
  project.dismissed = dismissed

  if get_main().config.save_on_change then
    get_main().save()
  end
end

--- Dismiss a file (mark as reviewed)
---@param filename string
function M.dismiss_file(filename)
  local dismissed = M.get_dismissed_files()
  dismissed[filename] = os.date("!%Y-%m-%dT%H:%M:%SZ")
  M.set_dismissed_files(dismissed)
end

--- Undismiss a file (show it again)
---@param filename string
function M.undismiss_file(filename)
  local dismissed = M.get_dismissed_files()
  dismissed[filename] = nil
  M.set_dismissed_files(dismissed)
end

--- Check if a file should be shown (not dismissed or changed after dismissal)
---@param filename string
---@param change_time string ISO timestamp of when file was changed
---@return boolean
function M.should_show_file(filename, change_time)
  local dismissed = M.get_dismissed_files()
  local dismiss_time = dismissed[filename]

  if not dismiss_time then
    return true
  end

  -- Show if file was changed after it was dismissed
  return change_time > dismiss_time
end

--- Navigate to a file
---@param filename string
function M.nav_to_file(filename)
  local cwd = utils.get_cwd()
  local filepath = filename

  -- Handle relative paths
  if not filename:match("^/") then
    filepath = cwd .. "/" .. filename
  end

  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filename, vim.log.levels.ERROR)
    return
  end

  -- Open the file
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

return M
