-- super_mini_llm.nvim - Minimal LLM plugin for Neovim
local config = require("super_mini_llm.config")
local providers = require("super_mini_llm.providers")
local ui = require("super_mini_llm.ui")

local M = {}

-- Track if currently processing a request
local is_processing = false

--- Setup the plugin
---@param opts table?
function M.setup(opts)
  config.apply(opts)
  M._create_commands()
end

--- Create user commands
function M._create_commands()
  -- :LLM command with optional range
  vim.api.nvim_create_user_command("LLM", function(cmd_opts)
    M._handle_llm_command(cmd_opts)
  end, {
    nargs = "+",
    range = true,
    desc = "Send text to LLM with prompt",
  })

  -- :LLMConfig command
  vim.api.nvim_create_user_command("LLMConfig", function(cmd_opts)
    local args = vim.split(cmd_opts.args, "%s+", { trimempty = true })

    if #args == 0 then
      -- Show all current config
      local provider = providers.get(config.current.provider)
      local model_display = config.current.model or (provider and provider.default_model .. " (default)") or "none"
      vim.api.nvim_echo({
        { "provider: ", "Normal" }, { config.current.provider .. "\n", "String" },
        { "model: ",    "Normal" }, { model_display, "String" },
      }, false, {})
      return
    end

    local option = args[1]
    local value = args[2]

    if option == "model" then
      if not value then
        local provider = providers.get(config.current.provider)
        local model_display = config.current.model or (provider and provider.default_model .. " (default)") or "none"
        vim.api.nvim_echo({ { "model: ", "Normal" }, { model_display, "String" } }, false, {})
      else
        config.current.model = value
        vim.api.nvim_echo({ { "model set to: ", "Normal" }, { value, "String" } }, false, {})
      end
    elseif option == "list_models" then
      local api_key, key_err = config.get_api_key()
      if not api_key then
        ui.show_error(key_err)
        return
      end
      local provider = providers.get(config.current.provider)
      if not provider or not provider.list_models then
        ui.show_error("Provider does not support listing models")
        return
      end
      vim.api.nvim_echo({ { "Fetching models...", "Comment" } }, false, {})
      provider.list_models(api_key, function(err, models)
        if err then
          ui.show_error(err)
          return
        end
        local lines = { { "Available models:\n", "Normal" } }
        for _, model in ipairs(models) do
          table.insert(lines, { "  " .. model .. "\n", "String" })
        end
        vim.api.nvim_echo(lines, true, {})
      end)
    elseif option == "provider" then
      if not value then
        vim.api.nvim_echo({ { "provider: ", "Normal" }, { config.current.provider, "String" } }, false, {})
      else
        if not providers.get(value) then
          ui.show_error("Unknown provider: " .. value .. ". Available: " .. table.concat(providers.list(), ", "))
          return
        end
        config.current.provider = value
        vim.api.nvim_echo({ { "provider set to: ", "Normal" }, { value, "String" } }, false, {})
      end
    else
      ui.show_error("Unknown option: " .. option .. ". Available: model, provider, list_models")
    end
  end, {
    nargs = "*",
    desc = "Show or set LLM configuration",
    complete = function(arg_lead, cmd_line)
      local args = vim.split(cmd_line, "%s+", { trimempty = true })
      -- args[1] is "LLMConfig", args[2] is option, args[3] is value
      if #args == 1 or (#args == 2 and not cmd_line:match("%s$")) then
        -- Completing option name
        return { "model", "provider", "list_models" }
      elseif args[2] == "model" then
        local provider = providers.get(config.current.provider)
        return provider and provider.models or {}
      elseif args[2] == "provider" then
        return providers.list()
      end
      return {}
    end,
  })
end

--- Handle the :LLM command
---@param cmd_opts table
function M._handle_llm_command(cmd_opts)
  -- Prevent concurrent requests
  if is_processing then
    ui.show_error("Already processing a request")
    return
  end

  local prompt = cmd_opts.args
  if prompt == "" then
    ui.show_error("Please provide a prompt")
    return
  end

  -- Get API key
  local api_key, key_err = config.get_api_key()
  if not api_key then
    ui.show_error(key_err)
    return
  end

  -- Get provider
  local provider = providers.get(config.current.provider)
  if not provider then
    ui.show_error("Unknown provider: " .. config.current.provider)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local start_line, end_line
  local use_range = cmd_opts.range == 2

  if use_range then
    -- Visual selection: use the range
    start_line = cmd_opts.line1
    end_line = cmd_opts.line2
  else
    -- No range: use entire buffer
    start_line = 1
    end_line = vim.api.nvim_buf_line_count(bufnr)
  end

  -- Get text from range (1-indexed lines)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local text = table.concat(lines, "\n")

  if text == "" then
    ui.show_error("No text to process")
    return
  end

  is_processing = true

  -- Show loading indicator (0-indexed line)
  local mark_id = ui.show_loading(bufnr, end_line - 1)

  -- Call the provider
  local model = config.current.model or provider.default_model
  provider.complete({
    text = text,
    prompt = prompt,
    system_prompt = config.current.system_prompt,
    model = model,
    api_key = api_key,
  }, function(err, result)
    is_processing = false
    ui.clear_loading(bufnr, mark_id)

    if err then
      ui.show_error(err)
      return
    end

    -- Replace the text
    -- Ensure buffer is still valid
    if not vim.api.nvim_buf_is_valid(bufnr) then
      ui.show_error("Buffer no longer valid")
      return
    end

    -- Split result into lines
    local new_lines = vim.split(result, "\n", { plain = true })

    -- Replace the range
    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_lines)

    ui.show_success("LLM response applied")
  end)
end

return M
