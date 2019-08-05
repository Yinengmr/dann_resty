local ssub = string.sub
local sgsub = string.gsub

local _M = {}

--對於excel表格的時間轉換
function _M.dateChange(dayChange)
    local time = '1899-12-30'
    if string.len(time) == 10 and 
       string.match(time, "%d%d%d%d%-%d%d%-%d%d") then
        local year  = ssub(time, 0, 4);   --年份
        local month = ssub(time, 6, 7);   --月
        local day   = ssub(time, 9, 10);  --日
        local time  = os.time({ year = year, 
                               month = month, 
                                 day = day }) 
              time  = time + dayChange*86400 --一天86400秒
      return (os.date('%Y',time).."-"..os.date('%m',time).."-"..os.date('%d',time))
  else
      return false
  end
end

return _M