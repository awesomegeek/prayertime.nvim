local M = require("lualine.component"):extend()



function M:init(options)
  options.icon = options.icon or { "󱠧", color = { fg = "#fcba03" } }
  M.super.init(self, options)
end

function M:update_status()
  return " Fajir-6:00"
end

return M
