local M = {}

local popup = require "plenary.popup"

local Win_id

function closePrayertimePopup()
    if vim.api.nvim_win_is_valid(Win_id) then
        vim.api.nvim_win_close(Win_id, true)
    end
end

function closePrayertimePopupSoon()
    vim.defer_fn(function()
        closePrayertimePopup()
    end, 1000)
end

function ShowPrayerTimePoup(praytimeList, cb)
    local height = 10
    local width = 30
    local borderchars = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"}

    Win_id = popup.create(praytimeList, {
        title = "Prayer Times",
        highlight = "PrayerTimesWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        padding = {0, 3, 0, 3},
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
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>lua closePrayertimePopup()<CR>", {
        silent = false
    })
    vim.api.nvim_set_current_win(Win_id)
    --   vim.api.nvim_command("autocmd BufLeave <buffer> silent! lua closePrayertimePopup()")
    vim.api.nvim_command("autocmd WinLeave <buffer> silent! lua closePrayertimePopupSoon()")

    vim.defer_fn(function()
        closePrayertimePopup()
    end, 10000)
end

function M.get_prayer_times(opts)
    opts = opts or {}
    local city = opts.city or "Cyberjaya"
    local coords = opts.coords or {"2.920162986", "101.652997388"}
    local timestamp = opts.date or os.date("*t")
    local method = opts.method or 2

    local prayTime = require('prayertime._prayertime'):new();
    prayTime:setCalcMethod(prayTime.MWL);
    local times = prayTime:getPrayerTimes(timestamp, coords[1], coords[2]);
    -- print('Fajr' , times[1]);
    local prayer_times = {
        string.format("Prayertime for %d/%d/%d", timestamp.year, timestamp.month, timestamp.day),
        "" .. opts.city,
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
    ShowPrayerTimePoup(prayer_times, nil)
end

function M.setup(opts)
    opts = opts or {}
    vim.keymap.set("n", "<Leader>h", function()
        if opts.city then
            M.get_prayer_times({
                city = opts.city,
                coords = opts.coords,
                method = opts.method
            })
        else
            print("Please set cityname and coordinates")
        end
    end)
end

return M
