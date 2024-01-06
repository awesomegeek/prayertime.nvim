local M = {}

local popup = require "plenary.popup"
local prayerNames = {
        'Fajr',
        'Sunrise',
        'Dhuhr',
        'Asr',
        'Sunset',
        'Maghrib',
        'Isha',
        -- 'Imsak'
}

local Win_id
M.confs = {}


function ClosePrayertimePopup()
  if vim.api.nvim_win_is_valid(Win_id) then
    vim.api.nvim_win_close(Win_id, true)
  end
end


function ClosePrayertimePopupSoon()
  vim.defer_fn(function()
    ClosePrayertimePopup()
  end, 1000)
end


local function displayInPopup(praytimeList, cb)
  local height = 10
  local width = 30
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

  Win_id = popup.create(praytimeList, {
    title = "Prayer Times",
    highlight = "PrayerTimesWindow",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    padding = { 0, 3, 0, 3 },
    minwidth = width,
    --   pos = "topright",
    borderchars = borderchars,
    cursorline = true,
    callback = cb,
    enter = true
  })
  local bufnr = vim.api.nvim_win_get_buf(Win_id)
  --   vim.api.nvim_buf_set_option(bufnr, "readonly", true)
  --   vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>lua ClosePrayertimePopup()<CR>", {
    silent = false
  })
  vim.api.nvim_set_current_win(Win_id)
  --   vim.api.nvim_command("autocmd BufLeave <buffer> silent! lua closePrayertimePopup()")
  vim.api.nvim_command("autocmd WinLeave <buffer> silent! lua ClosePrayertimePopupSoon()")

  vim.defer_fn(function()
    ClosePrayertimePopup()
  end, 10000)
end


M.getPrayerTimes = function(timestamp, timeformat)
  local opts = M.confs
  timeformat = timeformat or 1 -- 0 -> 24, 1 -> 12hr, 2 -> float

  -- local coords = opts.coords or { "2.920162986", "101.652997388" }
  if not opts.coords then
    print("Prayertime: Coords need to set")
  end
  local coords = opts.coords
  local timestamp = timestamp or os.date("*t")
  local method = opts.method or 3
  local prayTime = require('prayertime._prayertime'):new()
  prayTime:setCalcMethod(method)
  prayTime:setTimeFormat(timeformat)
  return prayTime:getPrayerTimes(timestamp, coords[1], coords[2])
end

local function getHourFloat(hour, minutes)
  return hour + minutes / 60
end


M.getNowAndNext = function()
  local now = os.date("*t")
  local nowFloat = getHourFloat(now.hour, now.min)
  -- local nowFloat = 14.43
  local ptimes = M.getPrayerTimes(now, 2)  -- get float times
  local ftimes = M.getPrayerTimes(now, 1)

  local currentIndex = 0
  local nextIndex = 0
  -- print("Now is " .. nowFloat)
  for i = 1, #ptimes - 1 do
    -- print(ptimes[i])
    if nowFloat > ptimes[i] and nowFloat < ptimes[i + 1] then
      print(ptimes[i])
      currentIndex = i
      nextIndex = i + 1
      break
    end
  end
  if currentIndex == 0 then
    currentIndex = 7
    nextIndex = 1
  end
  -- print('Current prayer time index ' .. currentIndex)
  local data = {}
  data["prev"] = {prayerNames[currentIndex], ftimes[currentIndex]}
  data["next"] = {prayerNames[nextIndex], ftimes[nextIndex]}
  -- print(data["prev"][1])
  -- print(data["next"][1])
  return data
end


M.formatPrayerTimes = function(times, timestamp)
  local opts = M.confs
  local city = opts.city or "Cyberjaya"
  local prayer_times = {
    string.format("Prayertime for %d/%d/%d", timestamp.year, timestamp.month, timestamp.day),
    "" .. city,
    "-------------------",
    "Imsak \t\t\t" .. times[8],
    "Fajr \t\t\t" .. times[1],
    "Sunrise \t\t" .. times[2],
    "Dhuhr \t\t\t" .. times[3],
    "Asr \t\t\t\t" .. times[4],
    "Sunset \t\t" .. times[5],
    "Maghrib \t\t" .. times[6],
    "Isha \t\t\t" .. times[7]
  }
  M.getNowAndNext()
  return prayer_times
end


M.showPrayerPopup = function()
  local for_date = os.date("*t")
  local times = M.getPrayerTimes(for_date)
  displayInPopup(M.formatPrayerTimes(times, for_date), nil)
end


function M.setup(opts)
  opts = opts or {}
  M.confs = opts
end


return M
