-- Provider registry and interface
local M = {}

-- Registry of available providers
local providers = {}

--- Register a provider
---@param provider table { name: string, complete: function }
function M.register(provider)
  if not provider.name then
    error("Provider must have a name")
  end
  if not provider.complete then
    error("Provider must have a complete function")
  end
  providers[provider.name] = provider
end

--- Get a provider by name
---@param name string
---@return table?
function M.get(name)
  return providers[name]
end

--- List all registered provider names
---@return string[]
function M.list()
  local names = {}
  for name, _ in pairs(providers) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

-- Register built-in providers
M.register(require("super_mini_llm.providers.anthropic"))

return M
