local tables = require("utils.tables")
local git_utils = require("utils.git")

local M = {}

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

local function trim(str)
  return (str:gsub("^%s*(.-)%s*$", "%1"))
end

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

local function parse_git_status(status)
  local lines = {}

  local pick = false
  local skip_next = false;
  for _, line in ipairs(status) do
    if skip_next then
      skip_next = false
      goto continue
    end

    if starts_with(line, "Changes to be committed:") or starts_with(trim(line), "(use") then
      pick = true
      skip_next = true

      goto continue
    end

    if pick and trim(line) == "" then
      pick = false
      break
    end

    if pick then
      table.insert(lines, trim(line))
    end

    ::continue::
  end

  return lines
end

local function open_floating_commit_window(callback, opts)
  local buf_commit = vim.api.nvim_create_buf(false, true)
  local buf_status = vim.api.nvim_create_buf(false, true)

  local width = 80
  local height_commit = 20
  local height_status = 10

  local spacing = 2

  -- Ensure windows are centered when opened
  local win_width = vim.api.nvim_get_option("columns")
  local win_height = vim.api.nvim_get_option("lines")

  local row_commit = math.floor((win_height - (height_commit + height_status + spacing)) / 2)
  local col_commit = math.floor((win_width - width) / 2)

  -- Calculate position for the status window
  local row_status = row_commit + height_commit + spacing

  -- Options for the commit message window
  local opts_commit = {
    title = opts.title or ' Commit message ',
    border = opts.border or 'rounded',
    title_pos = opts.title_pos or "center",
    relative = opts.relative or 'editor',
    width = opts.width or width,
    row = row_commit,
    col = col_commit,
    height = height_commit,
  }

  -- Populate the second buffer with changed files
  local changed_files = parse_git_status(get_git_status())
  if changed_files == nil or #changed_files == 0 then
    vim.notify("Could not find changed files", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(buf_status, 0, -1, false, changed_files)

  -- Make the buffer read-only
  vim.bo[buf_status].readonly = true
  vim.bo[buf_status].modifiable = false

  -- Options for the status window
  local opts_status = {
    title = ' Changed files ',
    title_pos = opts.title_pos or "center",
    relative = opts.relative or 'editor',
    width = width,
    style = opts.style or "minimal",
    height = #changed_files > 0 and #changed_files or height_status,
    row = row_status,
    col = col_commit,
    border = opts.border or 'rounded',
  }

  -- Open the changed files window
  local win_status = vim.api.nvim_open_win(buf_status, true, opts_status)
  vim.api.nvim_buf_set_option(buf_status, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf_status, 'bufhidden', 'wipe')

  -- Open the commit message window
  local win_commit = vim.api.nvim_open_win(buf_commit, true, opts_commit)
  vim.api.nvim_buf_set_option(buf_commit, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf_commit, 'bufhidden', 'wipe')

  vim.cmd('startinsert')

  if opts.exit_on_esc ~= false then
    vim.api.nvim_buf_set_keymap(buf_commit, 'n', '<Esc>', ':q!<CR>', { noremap = true, silent = true })
  end

  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf_commit,
    callback = function()
      local commit_message = vim.api.nvim_buf_get_lines(buf_commit, 0, -1, false)
      commit_message = table.concat(commit_message, "\n")

      callback(commit_message)

      if vim.api.nvim_win_is_valid(win_commit) then
        vim.api.nvim_win_close(win_commit, true)
      end

      if vim.api.nvim_win_is_valid(win_status) then
        vim.api.nvim_win_close(win_status, true)
      end
    end,
  })
end

local function is_stage_empty()
  local staged_changes = vim.fn.system("git diff --cached")

  return staged_changes == ""
end

function M.commit(opts)
  if is_stage_empty() then
    vim.notify("No staged changes to commit", vim.log.levels.INFO)
    return
  end

  local callback = function(commit_message)
    if commit_message == "" then
      vim.notify("Commit message is empty, aborting", vim.log.levels.WARN)
      return
    end

    -- Use a temporary file to store the commit message
    local temp_file = vim.fn.tempname()
    local file = io.open(temp_file, "w")
    if not file then
      vim.notify("Failed to create temporary file for commit", vim.log.levels.ERROR)
      return
    end

    file:write(commit_message)
    file:close()

    vim.cmd("Git commit -F " .. temp_file)

    os.remove(temp_file)
  end

  open_floating_commit_window(callback, opts)
end

function M.setup(opts)
  local cmd_opts = tables.merge_tables(
    opts.default or {},
    opts.commit or {}
  )

  if opts.enable ~= false then
    vim.api.nvim_create_user_command('GintCommit', function()
      M.commit(cmd_opts or {})
    end, {})
  end
end

return M
