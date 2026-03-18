-- Anthropic Claude provider
local request = require("super_mini_llm.request")

local M = {}

M.name = "anthropic"
M.default_model = "claude-sonnet-4-6"
M.models = {
  "claude-sonnet-4-6",
  "claude-opus-4-6",
  "claude-haiku-4-5-20251001",
}

local API_URL = "https://api.anthropic.com/v1/messages"
local API_VERSION = "2023-06-01"

local DEFAULT_SYSTEM_PROMPT = [[You are a text transformation tool. Your output will directly replace the input text in the user's editor.

Rules:
- Output ONLY the transformed text
- NO markdown formatting, NO code fences, NO backticks
- NO explanations, NO preamble, NO commentary
- Preserve the original formatting style (indentation, etc.) unless asked to change it]]

--- Complete text using Claude API
---@param opts table { text: string, prompt: string, system_prompt: string?, model: string, api_key: string }
---@param callback fun(err: string?, result: string?)
function M.complete(opts, callback)
  local headers = {
    ["Content-Type"] = "application/json",
    ["x-api-key"] = opts.api_key,
    ["anthropic-version"] = API_VERSION,
  }

  local user_content = string.format("%s\n\nInstruction: %s", opts.text, opts.prompt)

  local system = DEFAULT_SYSTEM_PROMPT
  if opts.system_prompt then
    system = system .. "\n\n" .. opts.system_prompt
  end

  local body = {
    model = opts.model,
    max_tokens = 4096,
    system = system,
    messages = {
      { role = "user", content = user_content },
    },
  }

  request.post(API_URL, headers, body, function(err, response)
    if err then
      callback(err)
      return
    end

    -- Check for API errors
    if response.error then
      local error_msg = response.error.message or vim.json.encode(response.error)
      callback("API error: " .. error_msg)
      return
    end

    -- Extract text from response
    if response.content and response.content[1] and response.content[1].text then
      callback(nil, response.content[1].text)
    else
      callback("Unexpected response format")
    end
  end)
end

--- List available models
---@param api_key string
---@param callback fun(err: string?, models: string[]?)
function M.list_models(api_key, callback)
  local headers = {
    ["x-api-key"] = api_key,
    ["anthropic-version"] = API_VERSION,
  }

  request.get("https://api.anthropic.com/v1/models", headers, function(err, response)
    if err then
      callback(err)
      return
    end

    if response.error then
      local error_msg = response.error.message or vim.json.encode(response.error)
      callback("API error: " .. error_msg)
      return
    end

    if response.data then
      local models = {}
      for _, model in ipairs(response.data) do
        table.insert(models, model.id)
      end
      table.sort(models)
      callback(nil, models)
    else
      callback("Unexpected response format")
    end
  end)
end

return M
