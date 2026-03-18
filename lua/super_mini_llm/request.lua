-- Async HTTP request layer using curl
local M = {}

local function make_request(method, url, headers, body, callback)
  local cmd = { "curl", "-s", "-X", method, url }

  for key, value in pairs(headers) do
    table.insert(cmd, "-H")
    table.insert(cmd, key .. ": " .. value)
  end

  if body then
    table.insert(cmd, "-d")
    table.insert(cmd, vim.json.encode(body))
  end

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

--- Make an async HTTP GET request
---@param url string
---@param headers table<string, string>
---@param callback fun(err: string?, response: table?)
function M.get(url, headers, callback)
  make_request("GET", url, headers, nil, callback)
end

--- Make an async HTTP POST request
---@param url string
---@param headers table<string, string>
---@param body table
---@param callback fun(err: string?, response: table?)
function M.post(url, headers, body, callback)
  make_request("POST", url, headers, body, callback)
end

return M

