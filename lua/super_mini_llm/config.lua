-- Configuration state and validation for super_mini_llm
local M = {}

-- Default configuration
M.defaults = {
  provider = "anthropic",
  model = "claude-sonnet-4-20250514",
  api_key = nil, -- string or function returning string
  system_prompt = nil,
}

-- Current configuration (set by setup())
M.current = vim.deepcopy(M.defaults)

--- Validate configuration
---@param config table
---@return boolean, string?
function M.validate(config)
  if config.provider and type(config.provider) ~= "string" then
    return false, "provider must be a string"
  end
  if config.model and type(config.model) ~= "string" then
    return false, "model must be a string"
  end
  if config.api_key and type(config.api_key) ~= "string" and type(config.api_key) ~= "function" then
    return false, "api_key must be a string or function"
  end
  if config.system_prompt and type(config.system_prompt) ~= "string" then
    return false, "system_prompt must be a string"
  end
  return true
end

--- Get API key
---@return string?, string?
function M.get_api_key()
  local key = M.current.api_key

  if not key then
    return nil, "No API key configured"
  end

  if type(key) == "function" then
    local ok, result = pcall(key)
    if not ok then
      return nil, "api_key function failed: " .. tostring(result)
    end
    return result
  end

  return key
end

--- Apply user configuration
---@param opts table?
function M.apply(opts)
  opts = opts or {}
  local ok, err = M.validate(opts)
  if not ok then
    error("super_mini_llm: invalid config: " .. err)
  end
  M.current = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
end

return M
