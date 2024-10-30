local M = {}

function M.merge_tables(...)
  local tab = {}

  for _, table in ipairs({ ... }) do
    if type(table) ~= "table" then
      return nil
    end

    for k, v in pairs(table) do
      tab[k] = v
    end
  end

  return tab
end

return M
