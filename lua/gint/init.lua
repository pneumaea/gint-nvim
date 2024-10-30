local M = {}

function test()
  vim.notify("This is a test")
end

function M.setup(opts)
  opts = opts or {}

  local keymap = opts.keymap or "<leader>hw"

  vim.keymap.set("n", keymap, M.test, {
    desc = "Test Command",
    silent = true
  })
end

return M
