local M = {}

function M.get_current_line()
  return vim.api.nvim_get_current_line()
end

return M
