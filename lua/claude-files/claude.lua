local M = {}

local utils = require("claude-files.utils")

--- Get the most recent session file for the current project
---@return string|nil
function M.get_latest_session_file()
  local project_dir = utils.get_claude_project_dir()

  -- Check if directory exists
  if vim.fn.isdirectory(project_dir) == 0 then
    return nil
  end

  -- Get all .jsonl files
  local files = vim.fn.glob(project_dir .. "/*.jsonl", false, true)

  if #files == 0 then
    return nil
  end

  -- Sort by modification time (most recent first)
  table.sort(files, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)

  -- Return the first non-agent file (agent-*.jsonl are sub-sessions)
  for _, file in ipairs(files) do
    local basename = vim.fn.fnamemodify(file, ":t")
    if not basename:match("^agent%-") then
      return file
    end
  end

  -- Fall back to first file if all are agent files
  return files[1]
end

--- Check if a file path is within the current working directory
--- Returns the relative path if it is, nil otherwise
---@param filepath string
---@param cwd string
---@return string|nil
local function get_relative_path_if_in_cwd(filepath, cwd)
  -- If it's already a relative path, it's within the project
  if not filepath:match("^/") then
    return filepath
  end

  -- If it's an absolute path, check if it starts with cwd
  if filepath:sub(1, #cwd) == cwd then
    -- Return the relative portion (skip cwd and the trailing slash)
    local relative = filepath:sub(#cwd + 2)
    if relative ~= "" then
      return relative
    end
  end

  -- File is outside the current working directory
  return nil
end

--- Parse a session file and extract changed files
---@param session_file string
---@return { filename: string, time: string }[]
local function parse_session_file(session_file)
  local files = {}
  local cwd = utils.get_cwd()

  local file = io.open(session_file, "r")
  if not file then
    return {}
  end

  for line in file:lines() do
    local ok, entry = pcall(vim.json.decode, line)
    if ok and entry and entry.type == "file-history-snapshot" then
      local snapshot = entry.snapshot
      if snapshot and snapshot.trackedFileBackups then
        for filepath, info in pairs(snapshot.trackedFileBackups) do
          -- Only include files within the current working directory
          local relative_path = get_relative_path_if_in_cwd(filepath, cwd)
          if relative_path then
            -- Store the most recent time for each file
            files[relative_path] = info.backupTime or ""
          end
        end
      end
    end
  end

  file:close()

  -- Convert to list and sort by time (most recent first)
  local result = {}
  for filepath, time in pairs(files) do
    table.insert(result, { filename = filepath, time = time })
  end

  table.sort(result, function(a, b)
    return a.time > b.time
  end)

  return result
end

--- Get files changed by Claude Code in the current session
---@return { filename: string, time: string }[]
function M.get_changed_files()
  local session_file = M.get_latest_session_file()
  if not session_file then
    return {}
  end

  return parse_session_file(session_file)
end

--- Check if Claude Code has session data for the current project
---@return boolean
function M.has_session_data()
  local project_dir = utils.get_claude_project_dir()
  return vim.fn.isdirectory(project_dir) == 1
end

return M
