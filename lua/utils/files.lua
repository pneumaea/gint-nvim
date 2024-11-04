local M = {}

local function split(str, sep)
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields + 1] = c end)

  return fields
end

local function is_file(str)
  local elements = split(str, '.')

  return #elements > 1
end

local function match_name(line)
  local file_regex = "(%.*/?[%w%.%_%-/]+)"

  return line:match(file_regex)
end

function M.get_file_name(line)
  local file_name = match_name(line)

  if is_file(file_name) then
    return file_name
  end
  local new_line = line:gsub(file_name, "", 1)
  while new_line ~= nil and #new_line > 0 and not is_file(file_name) do
    file_name = match_name(new_line)
    if file_name == nil or is_file(file_name) then break end

    new_line = new_line:gsub(file_name, "", 1)
  end

  if file_name ~= nil and is_file(file_name) then
    return file_name
  end

  return nil
end

return M
