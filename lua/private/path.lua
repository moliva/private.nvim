local M = {}

function M.get_current_path()
  local current_buf = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_name(current_buf)
end

function M.prompt_path()
  return vim.fn.input('Path > ')
end

return M
