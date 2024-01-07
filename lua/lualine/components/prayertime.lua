local M = require("lualine.component"):extend()


function M:init(options)
  options.icon = options.icon or { "󰕹", color = { fg = "#ffffff" } }
  M.super.init(self, options)
  self.last_minute = -1
  self.now_next_info = ""
end

function M:update_status()
  -- seem like update_status method refresh every seconds
  local current_minute = os.date("*t").min
  -- only refresh the calculation each minute
  if self.last_minute ~= current_minute then
    self.last_minute = current_minute
    -- calculate value here
    local now_next = require('prayertime').getNowAndNext()
    self.now_next_info = "" .. now_next["next"][1] .. " " .. now_next["next"][2]
  end
  return self.now_next_info
end

return M
