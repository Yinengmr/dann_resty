
local ssub = string.sub
local sgsub = string.gsub
local smatch = string.match
local sgmatch = string.gmatch
local sfind = string.find
local sgfind = string.gfind
local slen = string.len
local supper = string.upper
local utils = require("app.libs.utils")

local dims = {"G","Y","Q","M","W","D","H","N","S"}
local oper = {"+","-",":",','}
local rang = {"G" = { min = 0, max = 99},
              "Y" = { min = 1, max = 9999},
              "Q" = { min = 1, max = 4},
              "M" = { min = 1, max = 12},
              "W" = { min = 1, max = 54},
              "D" = { min = 1, max = 365},
              "H" = { min = 0, max = 23},
              "N" = { min = 0, max = 59},
              "S" = { min = 0, max = 59},
            }
}

--校驗字符
local function check_str(str)
  local string = supper(str)
  local table = {"Y","Q","M","W","D","H","N","S"}
  if utils.str_in_table(string,dims) then
    return true
  else
    return false
  end
end

--校驗運算符
local function check_operation(start)
  local table = {"+","-",":"}
  if utils.str_in_table(start,table) then
    return true
  else
    return false
  end
end

--校驗是否結尾
local function check_is_end(s,e)
  if s < e then
    return false
  else
    return true
  end
end

--判斷月份所屬季度的方法
local function check_quarter(month)
  if month == 0 then 
    return nil
  else
    local q, _ = math.modf( month / 4 )
    return q + 1
  end
end

--轉化季度爲月份
local function convert_quarter(quarter,year)
  local time1
  local time2
  if quarter == 1 then
    time1 = os.date("%Y-%m-%d",os.time{year = year, month = 1, day = 1})
    time2 = os.date("%Y-%m-%d",os.time{year = year, month = 3, day = 31})
  end
  if quarter == 2 then
    time1 = os.date("%Y-%m-%d",os.time{year = year, month = 4, day = 1})
    time2 = os.date("%Y-%m-%d",os.time{year = year, month = 6, day = 30})
  end
  if quarter == 3 then
    time1 = os.date("%Y-%m-%d",os.time{year = year, month = 7, day = 1})
    time2 = os.date("%Y-%m-%d",os.time{year = year, month = 9, day = 30})
  end
  if quarter == 4 then
    time1 = os.date("%Y-%m-%d",os.time{year = year, month = 10, day = 1})
    time2 = os.date("%Y-%m-%d",os.time{year = year, month = 12, day = 31})
  end
  return time1,time2
end

--檢驗是否爲空
local function check_is_nil(parameter)
  if parameter == nil or parameter == "" then
    return true
  else
    return false
  end
end

--拆分時間字符串，化爲年，月，日
local function split_time(time)
  --默認不帶時分秒的數據拆分
  local len = slen(time)
  local point1 = sfind(time,"-")
  local point2 = sfind(time,"-",point1 + 1)
  local year = tonumber(ssub(time,1,point1 - 1))
  local month = tonumber(ssub(time,point1 + 1,point2 - 1))
  local day = tonumber(ssub(time,point2 + 1,len))

  --如果存在時分秒，則返迴帶時分秒的參數
  local flag = sfind(time,"%s")
  if flag ~= nil then
    local point3 = sfind(time,":")
    local point4 = sfind(time,":",point3 + 1)
    year = tonumber(ssub(time,1,point1 - 1))
    month = tonumber(ssub(time,point1 + 1,point2 - 1))
    day = tonumber(ssub(time,point2 + 1,flag - 1))
    local hour = tonumber(ssub(time,flag + 1,point3 - 1))
    local minute = tonumber(ssub(time,point3 + 1,point4 - 1))
    local second = tonumber(ssub(time,point4 + 1,len))
    return year,month,day,hour,minute,second
  end

  return year,month,day
end

--獲取時間區間的開始日期
local function get_start(value)
  local index = sfind(value,"~")
  if index == nil then
    return nil
  end
  local time = ssub(value,1,index - 1)
  return time
end

--獲取時間區間的結束日期
local function get_stop(value)
  local index = sfind(value,"~")
  if index == nil then
    return nil
  end
  local time = ssub(value,index + 1,slen(value))
  return time
end

--校驗開始時間和結束時間是否符合格式
local function check_compare(start,stop)
  local year,month,day,hour,minute,second = split_time(start)
  local time1 = os.time{year = year,month = month,day = day,
                        hour = hour,min = minute,sec = second}
                        
  local year,month,day,hour,minute,second = split_time(stop)
  local time2 = os.time{year = year,month = month,day = day,
                        hour = hour,min = minute,sec = second}

  --開始時間不能大於結束時間
  if time1 < time2 then
    return true
  else
    return false
  end
end

--獲取當前子節點的約束範圍
local function get_table(head)
  local tab = {}

  if head == "Y" or head == "y" then
    tab = {"Q","M","W","D"}
  end
  if head == "Q" or head == "q" then
    tab = {"M","W","D"}
  end
  if head == "M" or head == "m" then
    tab = {"W","D"}
  end
  if head == "W" or head == "w" then
    tab = {"D"}
  end
  if head == "D" or head == "d" then
    tab = {"H"}
  end
  if head == "H" or head == "h" then
    tab = {"N"}
  end
  if head == "N" or head == "n" then
    tab = {"S"}
  end
  if head == "S" or head == "s" then
  end

  return tab
end

--計算每一年的第二週(避開第一週存在跨年的情況)
local function get_secondWeek(year,month,day)
  local w = tonumber(os.date("%w",os.time{year=year,month=month,day=1}))

  return year,month,8-w
end

--S_parameter 獲取拆分後不同字段的值
local function S_year(str)
  local min_size = 1
  local max_size = 9999
  local _,times = sgsub(str,"[yY]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local year = smatch(str,"[yY]%d*")
  local i,j = sfind(str,year)
  if i == j then
    return tonumber(os.date("%Y",os.time()))
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_quarter(str)
  local min_size = 1
  local max_size = 4
  local _,times = sgsub(str,"[qQ]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local quarter = smatch(str,"[qQ]%d*")
  local i,j = sfind(str,quarter)
  if i == j then
    local month = tonumber(os.date("%m",os.time()))
    return check_quarter(month)
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_month(str)
  local min_size = 1
  local max_size = 12
  local _,times = sgsub(str,"[mM]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local month = smatch(str,"[mM]%d*")
  local i,j = sfind(str,month)
  if i == j then
    return tonumber(os.date("%m",os.time()))
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_week(str)
  local min_size = 1
  local max_size = 53
  local _,times = sgsub(str,"[wW]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local week = smatch(str,"[wW]%d*")
  local i,j = sfind(str,week)
  if i == j then
    -- 如果當前時間是星期天，那麼起始周加1
    if tonumber(os.date("%w",os.time())) == 0 then
      return tonumber(os.date("%W",os.time())) + 1
    end
    return tonumber(os.date("%W",os.time()))
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_day(str)
  local min_size = 1
  local max_size = 366
  local _,times = sgsub(str,"[dD]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local day = smatch(str,"[dD]%d*")
  local i,j = sfind(str,day)
  if i == j then
    return tonumber(os.date("%j",os.time()))
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_hour(str)
  local min_size = 1
  local max_size = 24
  local _,times = sgsub(str,"[hH]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local day = smatch(str,"[hH]%d*")
  local i,j = sfind(str,day)
  if i == j then
    return tonumber(os.date("%H",os.time())) + 1
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_minute(str)
  local min_size = 1
  local max_size = 60
  local _,times = sgsub(str,"[nN]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local day = smatch(str,"[nN]%d*")
  local i,j = sfind(str,day)
  if i == j then
    return tonumber(os.date("%M",os.time()))
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

local function S_second(str)
  local min_size = 1
  local max_size = 60
  local _,times = sgsub(str,"[sS]%d*","%1")

  if times == 0 or times > 1 then
    return nil
  end

  local day = smatch(str,"[sS]%d*")
  local i,j = sfind(str,day)
  if i == j then
    return tonumber(os.date("%S",os.time()))
  end

  local size = tonumber(ssub(str,i+1,j))
  if size < min_size or size > max_size then
    return nil
  end

  return size
end

--T_parameter 將拆分得到的值轉化爲時間區間
local function T_year(num,time)
  local year = num
  if time ~= nil then
    year,_,_ = split_time(time)
    year = year + num
  end
  local time1 = os.date("%Y-%m-%d",os.time{year = year, month = 1, day = 1})
  local time2 = os.date("%Y-%m-%d",os.time{year = year, month = 12, day = 31})
  return time1.."~"..time2
end

local function T_quarter(num,time)
  local year = os.date("%Y",os.time())
  local quarter = num
  if time ~= nil then
    year,_,_ = split_time(time)
    local _,month,_ = split_time(time)
    local l1,f = math.modf((check_quarter(month) - 1 + num) / 4)
    if f < 0 then
      l1 = l1 - 1
    end
    local l2 = (check_quarter(month) - 1 + num) % 4
    quarter = l2 + 1
    year = year + l1
  end
  local time1,time2 = convert_quarter(quarter,year)
  return time1.."~"..time2
end

local function T_month(num,time)
  local year = os.date("%Y",os.time())
  local month = num
  if time ~= nil then
    year,month,_ = split_time(time)
    month = month + num
  end
  local time1 = os.date("%Y-%m-%d",os.time{year = year, month = month, day = 1})
  local time2 = os.date("%Y-%m-%d",os.time{year = year,
                        month = month + 1, day = 1} - 86400)
  return time1.."~"..time2
end

local function T_week(num,time)
  local year,month,day = get_secondWeek(split_time(os.date("%Y-1-1",os.time())))
  local week = num - 1
  if time ~= nil then 
    y,m,d = split_time(time)
    year,month,day = get_secondWeek(y,m,d)
    week = num
  end
  local time1 = os.date("%Y-%m-%d",os.time{year = year,
                        month = month, day = day} + 86400 * 7 * (week - 1))
  local time2 = os.date("%Y-%m-%d",os.time{year = year,
                        month = month, day = day} + 86400 * 7 * week - 86400)
  return time1.."~"..time2
end

local function T_day(num,time)
  local year = os.date("%Y",os.time())
  local month = 1
  local day = 1
  local hour = 0
  local minute = 0
  local second = 0
  local parameter = num
  if time ~= nil then
    year,month,day = split_time(time)
    parameter = num + 1
  end
  local time1 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + 86400 * (parameter - 1))
  local time2 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + 86400 * parameter - 1)
  return time1.."~"..time2
end

local function T_hour(num,time)
  local year,month,day = split_time(os.date("%Y-%m-%d"),os.time())
  local hour = 0
  local minute = 0
  local second = 0
  local parameter = num
  if time ~= nil then
    year,month,day,hour,minute,second = split_time(time)
    parameter = num + 1
  end
  local time1 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + 3600 * (parameter - 1))
  local time2 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + 3600 * parameter  - 1)
  return time1.."~"..time2
end

local function T_minute(num,time)
  local year,month,day = split_time(os.date("%Y-%m-%d"),os.time())
  local hour = 0
  local minute = 0
  local second = 0
  local parameter = num
  if time ~= nil then
    year,month,day,hour,minute,second = split_time(time)
    parameter = num + 1
  end
  local time1 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + 60 * (parameter - 1))
  local time2 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + 60 * parameter - 1)
  return time1.."~"..time2
end

local function T_second(num,time)
  local year,month,day = split_time(os.date("%Y-%m-%d"),os.time())
  local hour = 0
  local minute = 0
  local second = 0
  local parameter = num
  if time ~= nil then
    year,month,day,hour,minute,second = split_time(time)
    parameter = num + 1
  end
  local time1 = os.date("%Y-%m-%d %H:%M:%S",os.time{year = year, month = month, 
                        day = day, hour = hour, min = minute, sec = second} 
                        + (parameter - 1))
  return time1.."~"..time1
end

--加減運算
local function operation(head,value,num)
  local time = get_start(value)
  if head == "Y" or head == "y" then
    return T_year(num,time)
  end
  if head == "Q" or head == "q" then
    return T_quarter(num,time)
  end
  if head == "M" or head == "m" then
    return T_month(num,time)
  end
  if head == "W" or head == "w" then
    return T_week(num,time)
  end
  if head == "D" or head == "d" then
    return T_day(num,time)
  end
  if head == "H" or head == "h" then
    return T_hour(num,time)
  end
  if head == "N" or head == "n" then
    return T_minute(num,time)
  end
  if head == "S" or head == "s" then
    return T_second(num,time)
  end
end

--冒號運算
local function mathematical(start,parameter,value)
  local time = get_start(value)
  local values = nil

  if start == "Q" or start == "q" then
    local num = S_quarter(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_quarter(num - 1,time)
  end
  if start == "M" or start == "m" then
    local num = S_month(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_month(num - 1,time)
  end
  if start == "W" or start == "w" then
    local num = S_week(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_week(num - 1,time)
  end
  if start == "D" or start == "d" then
    local num = S_day(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_day(num - 1,time)
  end
  if start == "H" or start == "h" then
    local num = S_hour(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_hour(num - 1,time)
  end
  if start == "N" or start == "n" then
    local num = S_minute(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_minute(num - 1,time)
  end
  if start == "S" or start == "s" then
    local num = S_second(parameter)
    if num == nil then
      return "超出範圍"
    end
    values = T_second(num - 1,time)
  end

  return values
end

--單字段運算
local function transform(start,str)
  local value = nil

  if start == "Y" or start == "y" then
    local num = S_year(str)
    if num == nil then
      return "超出範圍"
    end
    value = T_year(num)
  end
  if start == "Q" or start == "q" then
    local num = S_quarter(str)
    if num == nil then
      return "超出範圍"
    end
    value = T_quarter(num)
  end
  if start == "M" or start == "m" then
    local num = S_month(str)
    if num == nil then
      return "超出範圍"
    end
    value = T_month(num)
  end
  if start == "W" or start == "w" then
    local num = S_week(str)
    if num == nil then
      return "超出範圍"
    end
    value = T_week(num)
  end
  if start == "D" or start == "d" then
    local num = S_day(str)
    if num == nil then
      return "超出範圍"
    end
    value = T_day(num)
  end
  if start == "H" or start == "h" then
    local num = S_hour(str)
    if num == nil then
      return "超出範圍"
    end
    value = T_hour(num)
  end
  if start == "N" or start == "n" then
    return "請指定該表達式的父約束(小時)"
  end
  if start == "S" or start == "s" then
    return "請指定該表達式的父約束(分鐘)"
  end

  return value
end

--拆分後續字段(運算符及其後續字段)
local function split_next(start,str,value,index)
  index = index + 1
  local len = slen(str)
  local head = start --父節點的首字母
  local begin = ssub(str,index,index)
  local values = nil
  local head_str = nil --待解析的字符串開頭

  if not check_operation(begin) then
    return "不符合規則的運算符號"
  end

  if begin == "+" then
    local num = smatch(str,"+(%d*)")
    if check_is_nil(num) then
      return "運算的數值不能爲空"
    end

    num = tonumber(num)
    index = index + slen(num)
    values = operation(head,value,num)
    head_str = head
  end
  if begin == "-" then
    local num = smatch(str,"-(%d*)")
    if check_is_nil(num) then
      return "運算的數值不能爲空"
    end
    
    num = - tonumber(num)
    index = index + slen(num) - 1
    values = operation(head,value,num)
    head_str = head
  end
  if begin == ":" then
    local parameter = smatch(str,":([yqmwdhnsYQMWDHNS]%d*)",index)
    if check_is_nil(parameter) then
      return "約束數值不能爲空"
    end

    local s = supper(ssub(parameter,1,1))
    head_str = s

    index = index + slen(parameter)
    
    if not utils.str_in_table(s,get_table(head)) then
      return "超出範圍限制"
    end

    values = mathematical(s,parameter,value)
  end

  if check_is_end(index,len) then
    return values
  end

  return split_next(head_str,str,values,index)
end

--拆分第一字段
local function split_first(str)
  local len = slen(str)
  local parameter = smatch(str,"([yqmwdhnsYQMWDHNS]%d*)")
  if check_is_nil(parameter) then
    return "待解析的字符串不符合解析規則"
  end

  local start = ssub(parameter,1,1)
  local index = slen(parameter)
  local value = nil

  value = transform(start,str)

  if check_is_end(index,len) then
    return value
  end

  return split_next(start,str,value,index)
end

--轉換函數主體
local function TimeConvert(str1,str2)

  if str1 == nil then
    return "參數不能爲空"
  end

  if str2 == nil then
    return split_first(str1)
  end

  local start = get_start(split_first(str1))
  local stop = get_start(split_first(str2))
  if utils.chk_is_null(start,stop) then
    return "請檢查參數是否符合解析要求"
  end

  if not check_compare(start,stop) then
    return "結束時間不能小於開始時間"
  end
  
  return start.."~"..stop
end

time_convert_router:get("",function(req,res,next)
  local src = req.query.src
  local str1 = req.query.str1
  local str2 = req.query.str2

  if src ~= "timeconvert" then
    return res:json({
      rv = 501,
      msg = "請檢查訪問鏈接"
    })
  end

  if utils.chk_is_null(str1) then
    return res:json({
      rv = 502,
      msg = "參數不能爲空"
    })
  end

  return res:json({
    rv = 200,
    msg = "解析完成",
    data = TimeConvert(str1,str2)
  })
end)

return time_convert_router
