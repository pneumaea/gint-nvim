local modules = {
  status = require("plugin.status"),
  commit = require("plugin.commit")
}

local M = {}

function M.setup(opts)
  opts = {
    default = opts.default or {},
    status = opts.status or {},
    commit = opts.commit or {}
  }

  for table, opt in pairs(opts) do
    if opt.enable ~= false then
      if table == "default" then goto continue end

      modules[table].setup(opts)

      ::continue::
    end
  end
end

return M
