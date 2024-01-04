# prayertime.nvim
Islamic prayer time for neovim (Work in progress)

## 📃 Introduction
This is simple plugin Muslim prayer times display in popup for today in neovim.

The calculation method is derived from the PrayTimes.org JS Library. This method was converted to Lua by [Mustafa Alyousef](https://github.com/mustafamsy) in his repo [prayertimes_lua](https://github.com/mustafamsy/prayertimes_lua).

## ⚡ Requirements

    Require 'nvim-lua/plenary.nvim'

## 📦 Installation

Calculations methods

0    -- Ithna Ashari
1    -- University of Islamic Sciences, Karachi
2    -- Islamic Society of North America (ISNA)
3    -- Muslim World League (MWL)
4    -- Umm al-Qura, Makkah
5    -- Egyptian General Authority of Survey
6    -- Custom Setting
7    -- Institute of Geophysics, University of Tehran
8    -- According to Al-Hadi Calender

```lua
-- lazy.nvim
{
   "awesomegeek/prayertime.nvim",
   dependencies = { "nvim-lua/plenary.nvim" },
   opts = {
      city = "Cyberjaya",
      coords = { "2.920162986", "101.652997388" },
      method = 2, -- Islamic Society of North America (ISNA)
   }
},
```