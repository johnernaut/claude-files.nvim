local M = {}

local Path = require("plenary.path")
local utils = require("claude-files.utils")

---@class ClaudeFilesConfig
---@field data_path string
---@field save_on_change boolean
---@field menu { width: number, height: number, borderchars: string[] }

---@type ClaudeFilesConfig
local default_config = {
  data_path = vim.fn.stdpath("data") .. "/claude-files.json",
  save_on_change = true,
  menu = {
    width = 60,
    height = 10,
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  },
}

---@type ClaudeFilesConfig
M.config = vim.deepcopy(default_config)

---@class ClaudeFilesData
---@field projects table<string, { dismissed: table<string, string> }>

---@type ClaudeFilesData
local data = { projects = {} }

--- Load persisted data from disk
local function load_data()
  local path = Path:new(M.config.data_path)
  if not path:exists() then
    return { projects = {} }
  end

  local ok, content = pcall(function()
    return path:read()
  end)

  if not ok or not content or content == "" then
    return { projects = {} }
  end

  local decoded = vim.json.decode(content)
  return decoded or { projects = {} }
end

--- Save data to disk
local function save_data()
  local path = Path:new(M.config.data_path)
  local parent = path:parent()

  if not parent:exists() then
    parent:mkdir({ parents = true })
  end

  path:write(vim.fn.json_encode(data), "w")
end

--- Get or create project data for the current working directory
---@return { dismissed: table<string, string> }
function M.get_project_data()
  local cwd = utils.get_cwd()
  if not data.projects[cwd] then
    data.projects[cwd] = { dismissed = {} }
  end
  return data.projects[cwd]
end

--- Setup the plugin
---@param opts ClaudeFilesConfig?
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
  data = load_data()
end

--- Save current state
function M.save()
  save_data()
end

--- Refresh data from disk
function M.refresh()
  data = load_data()
end

--- Toggle the changed files popup
function M.toggle()
  require("claude-files.ui").toggle()
end

return M
