-- Anthropic Claude provider
local request = require("super_mini_llm.request")

local M = {}

M.name = "anthropic"

local API_URL = "https://api.anthropic.com/v1/messages"
local API_VERSION = "2023-06-01"

--- Complete text using Claude API
---@param opts table { text: string, prompt: string, system_prompt: string?, model: string, api_key: string }
---@param callback fun(err: string?, result: string?)
function M.complete(opts, callback)
  local headers = {
    ["Content-Type"] = "application/json",
    ["x-api-key"] = opts.api_key,
    ["anthropic-version"] = API_VERSION,
  }

  -- Build user message combining text and prompt
  local user_content = string.format(
    "Here is the text:\n\n%s\n\nInstruction: %s",
    opts.text,
    opts.prompt
  )

  local body = {
    model = opts.model,
    max_tokens = 4096,
    messages = {
      { role = "user", content = user_content },
    },
  }

  -- Add system prompt if provided
  if opts.system_prompt then
    body.system = opts.system_prompt
  end

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

return M
