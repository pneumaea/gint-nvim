local tables = require("utils.tables")

local M = {}

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function needs_linebreak(line)
  local is_start_of_body = starts_with(line, "Changes")
  local is_end_of_body = starts_with(line, "Summary")
  local is_start_of_footer = starts_with(line, "no changes")

  return is_start_of_body or is_end_of_body or is_start_of_footer
end

local function get_git_status()
  local output = vim.fn.system("git status")

  if vim.v.shell_error ~= 0 then
    print("Error running git status: " .. output)
    return nil
  end

  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    if needs_linebreak(line) then
      table.insert(lines, "")
    end

    table.insert(lines, line)
  end

  return lines
end

local function git_status_float(opts)
  opts = opts or {}

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'syntax', 'git')

  local width = math.min(vim.o.columns - 2, opts.width or 80)
  local height = math.min(vim.o.lines - 2, opts.height or 20)

  local _ = vim.api.nvim_open_win(buf, true, {
    title = opts.title or ' Git status ',
    title_pos = opts.title_pos or "center",
    relative = opts.relative or 'editor',
    style = opts.style or 'minimal',
    width = opts.width or width,
    height = opts.height or height,
    border = opts.border or 'rounded',
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
  })

  local status_lines = get_git_status()
  if status_lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, status_lines)
  end

  vim.bo[buf].readonly = true
  vim.bo[buf].modifiable = false

  -- either true or default will enable this keymap
  if opts.exit_on_esc ~= false then
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':bd!<CR>', { noremap = true, silent = true })
  end
end

local function setup(opts)
  local cmd_opts = tables.merge_tables(
    opts.default or {},
    opts.status or {}
  )

  if opts.enable ~= false then
    vim.api.nvim_create_user_command('GitStatus', git_status_float, {})

    vim.keymap.set("n", "<leader>gs", function()
      git_status_float(cmd_opts or {})
    end, {})
  end
end

M.setup = setup

return M
