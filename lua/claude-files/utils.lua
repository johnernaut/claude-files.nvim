local M = {}

--- Encode a project path to Claude Code's format
--- /home/user/code/foo -> -home-user-code-foo
--- /home/user/.config/nvim -> -home-user--config-nvim
---@param path string
---@return string
function M.encode_project_path(path)
  -- Remove leading slash, replace slashes and dots with dashes
  local encoded = path:gsub("^/", ""):gsub("[/.]", "-")
  return "-" .. encoded
end

--- Get the current working directory
---@return string
function M.get_cwd()
  return vim.loop.cwd()
end

--- Normalize a file path relative to the project root
---@param filepath string
---@param root string?
---@return string
function M.normalize_path(filepath, root)
  root = root or M.get_cwd()
  if filepath:sub(1, #root) == root then
    filepath = filepath:sub(#root + 2) -- +2 to skip the trailing slash
  end
  return filepath
end

--- Get the Claude projects directory
---@return string
function M.get_claude_projects_dir()
  return vim.fn.expand("~/.claude/projects")
end

--- Get the Claude project directory for the current working directory
---@return string
function M.get_claude_project_dir()
  local cwd = M.get_cwd()
  local encoded = M.encode_project_path(cwd)
  return M.get_claude_projects_dir() .. "/" .. encoded
end

--- Format a relative time string
---@param timestamp string ISO 8601 timestamp
---@return string
function M.relative_time(timestamp)
  -- Parse ISO 8601 timestamp
  local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
  local year, month, day, hour, min, sec = timestamp:match(pattern)

  if not year then
    return ""
  end

  local file_time = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
  })

  local now = os.time()
  local diff = now - file_time

  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. "m ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. "h ago"
  else
    local days = math.floor(diff / 86400)
    return days .. "d ago"
  end
end

return M
