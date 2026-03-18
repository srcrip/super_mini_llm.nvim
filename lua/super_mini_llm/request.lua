-- Async HTTP request layer using curl
local M = {}

--- Make an async HTTP POST request
---@param url string
---@param headers table<string, string>
---@param body table
---@param callback fun(err: string?, response: table?)
function M.post(url, headers, body, callback)
  local json_body = vim.json.encode(body)

  -- Build curl command
  local cmd = { "curl", "-s", "-X", "POST", url }

  -- Add headers
  for key, value in pairs(headers) do
    table.insert(cmd, "-H")
    table.insert(cmd, key .. ": " .. value)
  end

  -- Add body
  table.insert(cmd, "-d")
  table.insert(cmd, json_body)

  -- Use vim.system for async execution (Neovim 0.10+)
  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback("curl failed: " .. (result.stderr or "unknown error"))
        return
      end

      if not result.stdout or result.stdout == "" then
        callback("Empty response from server")
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout)
      if not ok then
        callback("Failed to parse JSON response: " .. result.stdout)
        return
      end

      callback(nil, response)
    end)
  end)
end

return M
