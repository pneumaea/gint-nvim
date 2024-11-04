local M = {}

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

function M.needs_linebreak(line)
  local is_start_of_body = starts_with(line, "Changes")
  local is_body = starts_with(line, "Untracked")
  local is_end_of_body = starts_with(line, "Summary")
  local is_start_of_footer = starts_with(line, "no changes")

  return is_start_of_body or is_body or is_end_of_body or is_start_of_footer
end

return M
