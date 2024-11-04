local modules = {
  status = require("gint.status"),
  commit = require("gint.commit")
}
local args = require("utils.args")

local M = {}

M.modules = modules

function M.setup(opts)
  opts = args.verify(opts)

  for table, opt in pairs(opts) do
    if opt.enable ~= false then
      if table == "default" then goto continue end

      modules[table].setup(opts)

      ::continue::
    end
  end
end

return M
