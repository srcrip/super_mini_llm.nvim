-- UI feedback (virtual text loading indicator)
local M = {}

local ns_id = vim.api.nvim_create_namespace("super_mini_llm")

-- Track active indicators
local active_marks = {}

--- Show loading indicator
---@param bufnr number
---@param line number 0-indexed line number
---@return number extmark_id
function M.show_loading(bufnr, line)
  -- Ensure line is valid
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line >= line_count then
    line = line_count - 1
  end
  if line < 0 then
    line = 0
  end

  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
    virt_text = { { " ⏳ thinking...", "Comment" } },
    virt_text_pos = "eol",
  })

  active_marks[mark_id] = { bufnr = bufnr }

  -- Also echo to cmdline
  vim.api.nvim_echo({ { "LLM thinking...", "Comment" } }, false, {})

  return mark_id
end

--- Clear loading indicator
---@param bufnr number
---@param mark_id number?
function M.clear_loading(bufnr, mark_id)
  if mark_id then
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_id, mark_id)
    active_marks[mark_id] = nil
  else
    -- Clear all marks in buffer
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    for id, data in pairs(active_marks) do
      if data.bufnr == bufnr then
        active_marks[id] = nil
      end
    end
  end

  -- Clear cmdline
  vim.api.nvim_echo({ { "", "" } }, false, {})
end

--- Show error message
---@param msg string
function M.show_error(msg)
  vim.api.nvim_echo({ { "LLM Error: " .. msg, "ErrorMsg" } }, true, {})
end

--- Show success message
---@param msg string
function M.show_success(msg)
  vim.api.nvim_echo({ { msg, "Normal" } }, false, {})
end

return M
