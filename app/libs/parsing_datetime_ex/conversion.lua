local osdate = os.date
local ostime = os.time
local comon = require("app.libs.parsing_datetime_ex.comon")
local Y = "%Y"
local W  = "%W"
local y_d = "%Y-%m-%d"
local y_d_s = "%Y-%m-%d %H:%M:%S"
local _M = {}
local time_change = {}

function _M:conversion_year(num,time,basetime)
    local start_year = num
    local start_month = 1
    local start_day = 1
    local year_end = num
    local month_end = 12
    local day_end = 31
    if basetime then
      local date = osdate("*t",basetime)
      start_year,start_month,start_day = date.year,date.month,date.day
      start_year = start_year
      year_end = start_year + 1
      month_end = start_month
      day_end = start_day - 1
    end
    if time then
      local date = osdate("*t",time)
      start_year,start_month,start_day = date.year,date.month,date.day
      start_year = start_year + num
      year_end = start_year
      if start_month ~= 1 or start_day~= 1 then
        year_end = start_year + 1
        month_end = start_month
        day_end = start_day - 1
      end
    end
    local timestamp1 = ostime{year = start_year, month = start_month, day = start_day}
    local timestamp2 = ostime{year = year_end, month = month_end, day = day_end}
    local time1 = osdate(y_d,timestamp1)
    local time2 = osdate(y_d,timestamp2)
    time_change.from = timestamp1
    time_change.to = timestamp2
    time_change.from_str = time1
    time_change.to_str = time2
    return time_change
  end

  function _M:conversionTime(start,num,time,basetime)
    local year = osdate(Y,ostime())
    local secondesTable = {["D"] = 86400, ["H"] = 3600, ["N"] = 60, ["S"] = 1}
    local month, day, hour, minute, second, parameter = 1, 1, 0, 0, 0, num
    if start == "Y" then
        return  _M:conversion_year(num,time,basetime)
    end

    if start == "H" or start == "N" or start == "S" then
         local date = osdate("*t",ostime())
         year,month,day = date.year,date.month,date.day
         if basetime then
            local date = osdate("*t",basetime)
            year,month,day = date.year,date.month,date.day
         end
         if time then
            local date = osdate("*t",time)
            year,month,day,hour,minute,second =
                date.year,date.month,date.day,date.hour,date.minute,date.second
            parameter = num + 1
         end
    end
    if start == "D" then
        if basetime then
            year = osdate(Y,basetime)
        end
        if time then
            local date = osdate("*t",time)
            year,month,day = date.year,date.month,date.day
            if basetime then
                if date.yday == num +1 then
                    num = 0
                end
            end
            parameter = num +1
        end
    end
    if start == "W" then
        local week = num - 1
        if basetime then
            local date = osdate("*t",basetime)
            year,day = comon:get_secondWeek(date.year)
        else
            local date = osdate("*t",ostime())
            year,day = comon:get_secondWeek(date.year)
        end
        if time then
            local date = osdate("*t",time)
            year,day = comon:get_secondWeek(date.year)
            -- if basetime then
            --     week = osdate(W,time) + num + 1
            -- else
            --     week = osdate(W,time) + num + 1
            --     -- week = num + 1
            -- end
            week = osdate(W,time) + num + 1
        end
        local timestamp1 = ostime{year = year,month = month, day = day}
                                      + 86400 * 7 * (week - 1)
        local timestamp2 = ostime{year = year,month = month, day = day}
                                      + 86400 * 7 * week - 86400
        local time1 = osdate(y_d,timestamp1)
        local time2 = osdate(y_d,timestamp2)
        time_change.from = timestamp1
        time_change.to = timestamp2
        time_change.from_str = time1
        time_change.to_str = time2
        return time_change
    end
    if start == "M" then
        if basetime then
            year = osdate(Y,basetime)
        end
        month = num
       if time then
           local date = osdate("*t",time)
           year,month = date.year,date.month
        --    if basetime then
        --        month = month + num
        --    end
           month = month + num
               -- ngx.log(ngx.ERR, "month:::"..year..month)
       end
       local timestamp1 = ostime{year = year,month = month, day = 1}
       local timestamp2 = ostime{year = year,month = month + 1, day = 1} - 86400
       local time1 = osdate(y_d,timestamp1)
       local time2 = osdate(y_d,timestamp2)
       time_change.from = timestamp1
       time_change.to = timestamp2
       time_change.from_str = time1
       time_change.to_str = time2
       return time_change
    end
    if start == "Q" then
        if basetime then
             year = osdate(Y,basetime)
        end
        local quarter = num
        if time then
          local date = osdate("*t",time)
          year,month = date.year, date.month
          local l1,f = math.modf((comon:check_quarter(month) - 1 + num) / 4)
          if f < 0 then
            l1 = l1 - 1
          end
          local l2 = (comon:check_quarter(month) - 1 + num) % 4
          quarter = l2 + 1
        --   if basetime then
        --     --     quarter = num + quarter
        --   else
        --     year = year + l1
        --   end
          year = year + l1
        end
        local timestamp1,timestamp2,time1,time2 = comon:convert_quarter(quarter,year)
        time_change.from = timestamp1
        time_change.to = timestamp2
        time_change.from_str = time1
        time_change.to_str = time2
        return time_change
    end
    local timestamp1 = ostime{year = year, month = month, day = day,
                                  hour = hour, min = minute, sec = second}
                                      + secondesTable[start] * (parameter - 1)
    local timestamp2 = ostime{year = year, month = month, day = day,
                                  hour = hour, min = minute, sec = second}
                                      + secondesTable[start] * parameter - 1
    local time1 = osdate(y_d_s,timestamp1)
    local time2 = osdate(y_d_s,timestamp2)
    time_change.from = timestamp1
    time_change.to = timestamp2
    time_change.from_str = time1
    time_change.to_str = time2
    return time_change
end

  return _M
