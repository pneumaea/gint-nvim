local tables = require("utils.tables")
local nvim_utils = require("utils.nvim")
local file_utils = require("utils.files")
local git_utils = require("utils.git")

local M = {}

local function get_git_status()
  local output = vim.fn.system("git status")

  if vim.v.shell_error ~= 0 then
    print("Error running git status: " .. output)
    return nil
  end

  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    if git_utils.needs_linebreak(line) then
      table.insert(lines, "")
    end

    table.insert(lines, line)
  end

  return lines
end

function M.stage_line()
  local line = nvim_utils.get_current_line()

  local file_name = file_utils.get_file_name(line)
  if file_name == nil then
    return
  end

  local output = vim.fn.system("git add " .. file_name)
  if vim.v.shell_error ~= 0 then
    vim.notify("Error running git add: " .. output, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local status_lines = get_git_status()
  if status_lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, status_lines)
  end
end

function M.unstage_line()
  local line = nvim_utils.get_current_line()

  local file_name = file_utils.get_file_name(line)
  if file_name == nil then
    return
  end

  local output = vim.fn.system("git reset " .. file_name)
  if vim.v.shell_error ~= 0 then
    vim.notify("Error running git reset: " .. output, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local status_lines = get_git_status()
  if status_lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, status_lines)
  end
end

local function attach_keymaps(buf, opts)
  if opts.exit_on_esc ~= false then
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':q!<CR>', { noremap = true, silent = true })
  end

  vim.api.nvim_buf_set_keymap(buf, 'n', 'c', '', {
    noremap = true,
    silent = true,
    callback = function()
      vim.cmd('q!')
      require("gint.commit").commit()
    end
  })


  if opts.no_remap == true then
    return
  end

  vim.api.nvim_buf_set_keymap(buf, 'n', 'i', ':lua require("gint.status").stage_line()<CR>',
    { noremap = true, silent = true })

  vim.api.nvim_buf_set_keymap(buf, 'n', 'x', ':lua require("gint.status").unstage_line()<CR>',
    { noremap = true, silent = true })
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

  -- vim.bo[buf].readonly = true
  vim.bo[buf].modifiable = true

  attach_keymaps(buf, opts)
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
