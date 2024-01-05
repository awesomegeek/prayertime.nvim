--------------------- Copyright Block ----------------------
--[[

PrayTime.java: Prayer Times Calculator (ver 1.0)
Copyright (C) 2007-2023 PrayTimes.org

Lua Code By: Mustafa Al-Yousef
Original JS Code By: Hamid Zarrabi-Zadeh

License: MIT

This program is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY.

PLEASE DO NOT REMOVE THIS COPYRIGHT BLOCK.

]]--

local PrayTime = {}
PrayTime.__index = PrayTime

-- Calculation Methods
PrayTime.Jafari     = 0    -- Ithna Ashari
PrayTime.Karachi    = 1    -- University of Islamic Sciences, Karachi
PrayTime.ISNA       = 2    -- Islamic Society of North America (ISNA)
PrayTime.MWL        = 3    -- Muslim World League (MWL)
PrayTime.Makkah     = 4    -- Umm al-Qura, Makkah
PrayTime.Egypt      = 5    -- Egyptian General Authority of Survey
PrayTime.Custom     = 6    -- Custom Setting
PrayTime.Tehran     = 7    -- Institute of Geophysics, University of Tehran
PrayTime.Bahrain    = 8    -- According to Al-Hadi Calender
local Imsak_offset  = 8.3  -- Change this im minutes according to school/method


-- Juristic Methods
PrayTime.Shafii     = 0    -- Shafii (standard)
PrayTime.Hanafi     = 1    -- Hanafi

-- Adjusting Methods for Higher Latitudes
PrayTime.None       = 0    -- No adjustment
PrayTime.MidNight   = 1    -- middle of night
PrayTime.OneSeventh = 2    -- 1/7th of night
PrayTime.AngleBased = 3    -- angle/60th of night

-- Time Formats
PrayTime.Time24     = 0    -- 24-hour format
PrayTime.Time12     = 1    -- 12-hour format
PrayTime.Time12NS   = 2    -- 12-hour format with no suffix
PrayTime.Float      = 2    -- 12-hour format with no suffix


PrayTime.timeNames = {
        'Fajr',
        'Sunrise',
        'Dhuhr',
        'Asr',
        'Sunset',
        'Maghrib',
        'Isha',
        'Imsak'
    }


PrayTime.InvalidTime = "-----" -- The string used for invalid times

PrayTime.calcMethod   = 0;      -- caculation method
PrayTime.asrJuristic  = 0;      -- Juristic method for Asr
PrayTime.dhuhrMinutes = 0;      -- minutes after mid-day for Dhuhr
PrayTime.adjustHighLats = 1;    -- adjusting method for higher latitudes

PrayTime.timeFormat   = 0;      -- time format

-- Technical Settings
PrayTime.numIterations = 1      -- number of iterations needed to compute times

-- Calc Method Parameters
PrayTime.methodParams = {}

function PrayTime:new(methodID)
    methodID = methodID or 0
    local newObj = {}
    setmetatable(newObj, self)
    self.__index = self

    -- Initialize methodParams with default values
    newObj.methodParams[self.Jafari]  = {16, 0, 4, 0, 14}
    newObj.methodParams[self.Karachi] = {18, 1, 0, 0, 18}
    newObj.methodParams[self.ISNA]    = {15, 1, 0, 0, 15}
    newObj.methodParams[self.MWL]     = {18, 1, 0, 0, 17}
    newObj.methodParams[self.Makkah]  = {18.5, 1, 0, 1, 90}
    newObj.methodParams[self.Egypt]   = {19.5, 1, 0, 0, 17.5}
    newObj.methodParams[self.Tehran]  = {17.7, 0, 4.5, 0, 14}
    newObj.methodParams[self.Custom]  = {18, 1, 0, 0 ,17}
    newObj.methodParams[self.Bahrain] = {17.6, 0, 4, 0, 14}

    newObj:setCalcMethod(methodID)

    return newObj
end

function PrayTime:setCalcMethod(methodID)
    self.calcMethod = methodID
end

-- return prayer times for a given date
function PrayTime:getDatePrayerTimes(year, month, day, latitude, longitude, timeZone)
    self.lat = latitude
    self.lng = longitude
    -- self.timeZone = timeZone
    self.timeZone = self:getTimeZone({year=year, month=month, day=day})
    self.JDate = self:julianDate(year, month, day) - longitude / (15 * 24)
    return self:computeDayTimes()
end

-- return prayer times for a given timestamp
function PrayTime:getPrayerTimes(timestamp, latitude, longitude, timeZone)
    local date = timestamp
    return self:getDatePrayerTimes(date.year, date.month, date.day, latitude, longitude, timeZone)
end

-- set the juristic method for Asr
function PrayTime:setAsrMethod(methodID)
    if methodID < 0 or methodID > 1 then
        return
    end
    self.asrJuristic = methodID
end

-- set the angle for calculating Fajr
function PrayTime:setFajrAngle(angle)
    self:setCustomParams({angle,nil,nil,nil,nil})
end

function PrayTime:setMaghribAngle(angle)
       self:setCustomParams({nil, 0, angle,nil,nil})
end

-- set the angle for calculating Isha
function PrayTime:setIshaAngle(angle)
    self:setCustomParams({nil,nil,nil,0,angle})
end

-- set the minutes after mid-day for calculating Dhuhr
function PrayTime:setDhuhrMinutes(minutes)
    self.dhuhrMinutes = minutes
end

-- set the minutes after Sunset for calculating Maghrib
function PrayTime:setMaghribMinutes(minutes)
    self:setCustomParams({nil,1,minutes,nil,nil})
end

-- set the minutes after Maghrib for calculating Isha
function PrayTime:setIshaMinutes(minutes)
    self:setCustomParams({nil,nil,nil,1,minutes})
end

-- set custom values for calculation parameters
function PrayTime:setCustomParams(params)
    for i = 1, 5 do
        if params[i] == nil then
            self.methodParams[self.Custom][i] = self.methodParams[self.calcMethod][i]
        else
            self.methodParams[self.Custom][i] = params[i]
        end
    end
    self.calcMethod = self.Custom
end

-- set adjusting method for higher latitudes
function PrayTime:setHighLatsMethod(methodID)
    self.adjustHighLats = methodID
end

-- set the time format
function PrayTime:setTimeFormat(timeFormat)
    self.timeFormat = timeFormat
end

-- convert float hours to 24h format
function PrayTime:floatToTime24(time)
    if time ~= time then
        return self.InvalidTime;
    end
    time = self:fixhour(time + 0.5 / 60); -- add 0.5 minutes to round
    local hours = math.floor(time);
    local minutes = math.floor((time - hours) * 60);
    return self:twoDigitsFormat(hours) .. ':' .. self:twoDigitsFormat(minutes);
end

-- convert float hours to 12h format
function PrayTime:floatToTime12(time, noSuffix)
    if time ~= time then
        return self.InvalidTime;
    end
    time = self:fixhour(time + 0.5 / 60); -- add 0.5 minutes to round
    local hours = math.floor(time);
    local minutes = math.floor((time - hours) * 60);
    local suffix = hours >= 12 and ' pm' or ' am';
    hours = (hours + 12 - 1) % 12 + 1;
    return hours .. ':' .. self:twoDigitsFormat(minutes) .. (noSuffix and '' or suffix);
end

-- convert float hours to 12h format with no suffix
function PrayTime:floatToTime12NS(time)
    return self:floatToTime12(time, true);
end

-- compute declination angle of sun and equation of time
function PrayTime:sunPosition(jd)
    local D = jd - 2451545.0
    local g = self:fixangle(357.529 + 0.98560028 * D)
    local q = self:fixangle(280.459 + 0.98564736 * D)
    local L = self:fixangle(q + 1.915 * self:dsin(g) + 0.020 * self:dsin(2 * g))

    local R = 1.00014 - 0.01671 * self:dcos(g) - 0.00014 * self:dcos(2 * g)
    local e = 23.439 - 0.00000036 * D

    local d = self:darcsin(self:dsin(e) * self:dsin(L))
    local RA = self:darctan2(self:dcos(e) * self:dsin(L), self:dcos(L)) / 15
    RA = self:fixhour(RA)
    local EqT = q / 15 - RA

    return {d, EqT}
end

-- compute equation of time
function PrayTime:equationOfTime(jd)
    local sp = self:sunPosition(jd)
    return sp[2]
end

-- compute declination angle of sun
function PrayTime:sunDeclination(jd)
    local sp = self:sunPosition(jd)
    return sp[1]
end

-- compute mid-day (Dhuhr, Zawal) time
function PrayTime:computeMidDay(t)
    local T = self:equationOfTime(self.JDate + t)
    local Z = self:fixhour(12 - T)
    return Z
end

-- compute time for a given angle G
function PrayTime:computeTime(G, t)
    local D = self:sunDeclination(self.JDate + t)
    local Z = self:computeMidDay(t)
    local V = 1 / 15 * self:darccos((-self:dsin(G) - self:dsin(D) * self:dsin(self.lat)) /
            (self:dcos(D) * self:dcos(self.lat)))
    return Z + (G > 90 and -V or V)
end

-- compute the time of Asr. Shafii: step=1, Hanafi: step=2
function PrayTime:computeAsr(step, t)
    local D = self:sunDeclination(self.JDate + t)
    local G = -self:darccot(step + self:dtan(math.abs(self.lat - D)))
    return self:computeTime(G, t)
end

-- compute prayer times at given julian date
function PrayTime:computeTimes(times)
    local t = self:dayPortion(times)

    -- local Imsak = self:computeTime(180 - self.methodParams[self.calcMethod][1], t[1] + Imsak_offset)
    -- TODO: Need to confirm this. I think need to minus the time for IMSAK
    local Imsak = self:computeTime(180 - self.methodParams[self.calcMethod][1], t[1] - Imsak_offset)

    local Fajr = self:computeTime(180 - self.methodParams[self.calcMethod][1], t[1])
    local Sunrise = self:computeTime(180 - 0.833, t[2])
    local Dhuhr = self:computeMidDay(t[3])
    local Asr = self:computeAsr(1 + self.asrJuristic, t[4])
    local Sunset = self:computeTime(0.833, t[5])
    local Maghrib = self:computeTime(self.methodParams[self.calcMethod][3], t[6])
    local Isha = self:computeTime(self.methodParams[self.calcMethod][5], t[7])

    return {Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha, Imsak}
end

-- compute prayer times at given julian date
function PrayTime:computeDayTimes()
    local times = {5, 6, 12, 13, 18, 18, 18, 5} -- default times

    for i = 1, self.numIterations do
        times = self:computeTimes(times)
    end

    times = self:adjustTimes(times)
    return self:adjustTimesFormat(times)
end

-- adjust times in a prayer time array
function PrayTime:adjustTimes(times)
    for i = 1, 8 do
        times[i] = times[i] + self.timeZone - self.lng / 15
    end
    times[3] = times[3] + self.dhuhrMinutes / 60 -- Dhuhr
    if (self.methodParams[self.calcMethod][2] == 1) then -- Maghrib
        times[6] = times[5] + self.methodParams[self.calcMethod][3] / 60
    end
    if (self.methodParams[self.calcMethod][4] == 1) then -- Isha
        times[7] = times[6] + self.methodParams[self.calcMethod][5] / 60
    end

    if (self.adjustHighLats ~= self.None) then
        times = self:adjustHighLatTimes(times)
    end

    return times
end

-- convert times array to given time format
function PrayTime:adjustTimesFormat(times)
    if self.timeFormat == self.Float then
        return times
    end
    for i = 1, 8 do
        if self.timeFormat == self.Time12 then
            times[i] = self:floatToTime12(times[i])
        elseif self.timeFormat == self.Time12NS then
            times[i] = self:floatToTime12(times[i], true)
        else
            times[i] = self:floatToTime24(times[i])
        end
    end
    return times;
end

-- adjust Fajr, Isha and Maghrib for locations in higher latitudes
function PrayTime:adjustHighLatTimes(times)
    local nightTime = self:timeDiff(times[5], times[2]) -- sunset to sunrise

    -- Adjust Fajr
    local FajrDiff = self:nightPortion(self.methodParams[self.calcMethod][1]) * nightTime;
    if (times[1] ~= times[1]) or (self:timeDiff(times[1], times[2]) > FajrDiff) then --isnan check for lua is x~=x
        times[1] = times[2] - FajrDiff;
    end

    -- Adjust Isha
    local IshaAngle = (self.methodParams[self.calcMethod][4] == 0) and self.methodParams[self.calcMethod][5] or 18;
    local IshaDiff = self:nightPortion(IshaAngle) * nightTime;
    if (times[7] ~= times[7]) or (self:timeDiff(times[5], times[7]) > IshaDiff) then --isnan check for lua is x~=x
        times[7] = times[5] + IshaDiff;
    end

     -- Adjust Maghrib
    local MaghribAngle = (self.methodParams[self.calcMethod][2] == 0) and self.methodParams[self.calcMethod][3] or 4;
    local MaghribDiff = self:nightPortion(MaghribAngle) * nightTime;

    if (times[6] ~= times[6]) or (self:timeDiff(times[5], times[6]) > MaghribDiff) then --isnan check for lua is x~=x
        times[6] = times[5] + MaghribDiff;
    end

    return times;
end

-- the night portion used for adjusting times in higher latitudes
function PrayTime:nightPortion(angle)
    if self.adjustHighLats == self.AngleBased then
        return 1 / 60 * angle;
    end
    if self.adjustHighLats == self.MidNight then
        return 1 / 2;
    end
    if self.adjustHighLats == self.OneSeventh then
        return 1 / 7;
    end
end

-- convert hours to day portions
function PrayTime:dayPortion(times)
    for i = 1, 8 do
        times[i] = times[i] / 24;
    end
    return times;
end

------------------------ Misc Functions -----------------------

-- compute the difference between two times
function PrayTime:timeDiff(time1, time2)
    return self:fixhour(time2 - time1);
end

-- add a leading 0 if necessary
function PrayTime:twoDigitsFormat(num)
    if num < 10 then
        return '0' .. num;
    else
        return num;
    end
end

------------------------ Julian Date Functions -----------------------

-- calculate julian date from a calendar date
function PrayTime:julianDate(year, month, day)
    if month <= 2 then
        year = year - 1;
        month = month + 12;
    end
    local A = math.floor(year / 100);
    local B = 2 - A + math.floor(A / 4);

    local JD =
        math.floor(365.25 * (year + 4716)) +
        math.floor(30.6001 * (month + 1)) +
        day +
        B -
        1524.5;
    return JD;
end

-- convert a calendar date to julian date (second method)
function PrayTime:calcJD(year, month, day)
    local J1970 = 2440588.0;
    local date = year .. '-' .. month .. '-' .. day;
    local ms = os.time({year=year,month=month,day=day}); -- # of seconds since midnight Jan 1, 1970
    local days = math.floor(ms / (60 * 60 *24));
    return J1970 + days - 0.5;
end

------------------------ Trigonometric Functions -----------------------

-- degree sin
function PrayTime:dsin(d)
    return math.sin(self:dtr(d));
end

-- degree cos
function PrayTime:dcos(d)
    return math.cos(self:dtr(d));
end

-- degree tan
function PrayTime:dtan(d)
    return math.tan(self:dtr(d));
end

-- degree arcsin
function PrayTime:darcsin(x)
    return self:rtd(math.asin(x));
end

-- degree arccos
function PrayTime:darccos(x)
    return self:rtd(math.acos(x));
end

-- degree arctan
function PrayTime:darctan(x)
    return self:rtd(math.atan(x));
end

-- degree arctan2
function PrayTime:darctan2(y, x)
    return self:rtd(math.atan2(y, x));
end

-- degree arccot
function PrayTime:darccot(x)
    return self:rtd(math.atan(1 / x));
end

-- degree to radian
function PrayTime:dtr(d)
    return (d * math.pi) / 180.0;
end

-- radian to degree
function PrayTime:rtd(r)
    return (r * 180.0) / math.pi;
end

-- range reduce angle in degrees.
function PrayTime:fixangle(a)
    a = a - 360.0 * math.floor(a / 360.0);
    a = a < 0 and a + 360.0 or a;
    return a;
end

-- range reduce hours to 0..23
function PrayTime:fixhour(a)
    a = a - 24.0 * math.floor(a / 24.0);
    a = a < 0 and a + 24.0 or a;
    return a;
end

------------------------ Time Zone Functions -----------------------

-- get local time zone
function PrayTime:getTimeZone(date)
    local year = date.year
    local t1 = self:gmtOffset({year=year, month=1, day=1})
    local t2 = self:gmtOffset({year=year, month=7, day=1})
    return math.min(t1, t2)
end

-- get daylight saving for a given date
function PrayTime:getDst(date)
    -- You can use the os.date function to get the current timezone offset
    local timezoneOffset = os.date("*t").isdst and 1 or 0
    return timezoneOffset
end

-- GMT offset for a given date
function PrayTime:gmtOffset(date)
    local year, month, day = date.year, date.month, date.day
    local timestamp = os.time{year=year, month=month, day=day}
    local utcDate = os.date("!*t", timestamp)
    local localDate = os.date("*t", timestamp)
    local utcTimestamp = os.time(utcDate)
    local localTimestamp = os.time(localDate)
    local hoursDiff = os.difftime(localTimestamp, utcTimestamp) / 3600
    return hoursDiff
end

------------------------ Helper Functions -----------------------


-- Print Table
function print_r(t, name, indent)
    local tableList = {}
    function table_r (t, name, indent, full)
        local serial=string.len(full) == 0 and name or type(name)~="number" and '["'..tostring(name)..'"]' or '['..name..']'
        io.write(indent,serial,' = ')
        if type(t) == "table" then
            if tableList[t] ~= nil then
                io.write('{}; -- ',tableList[t],' (self reference)\n')
            else
                tableList[t]=full..serial
                if next(t) then -- Table not empty
                    io.write('{\n')
                    for key,value in pairs(t) do table_r(value,key,indent..'\t',full..serial) end
                    io.write(indent,'};\n')
                else io.write('{};\n') end
            end
        else
            io.write(type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"' or tostring(t),';\n')
        end
  end
  table_r(t,name or '__unnamed__',indent or '','')
end

return PrayTime