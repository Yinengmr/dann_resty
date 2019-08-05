local ssub = string.sub
local sfind = string.find
local slen = string.len
local tonum = tonumber
local osdate = os.date
local ostime = os.time
local y_d = "%Y-%m-%d"
local _M = {}
--校驗運算符
function _M:check_operation(start)
    local table = {"+","-",":"}
    for _, v in pairs(table) do
        if v == start then
            return true
        end
    end
      return false
  end
  --校驗是否結尾
function _M:check_is_end(s,e)
    if s < e then
      return false
    else
      return true
    end
end
  --判斷月份所屬季度的方法
function _M:check_quarter(month)
    if 1 <= month and month <= 3 then
      return 1
    end
    if 4 <= month and month <= 6 then
      return 2
    end
    if 7 <= month and month <= 9 then
      return 3
    end
    if 10 <= month and month <= 12 then
      return 4
    end
    return nil
end

  --轉化季度爲月份
function _M:convert_quarter(quarter,year)
    local timestamp1 = nil
    local timestamp2 = nil
    local time1 = nil
    local time2 = nil

    if quarter == 1 then
      timestamp1 = ostime{year = year, month = 1, day = 1}
      timestamp2 = ostime{year = year, month = 3, day = 31}
      time1 = osdate(y_d,timestamp1)
      time2 = osdate(y_d,timestamp2)
    end
    if quarter == 2 then
      timestamp1 = ostime{year = year, month = 4, day = 1}
      timestamp2 = ostime{year = year, month = 6, day = 30}
      time1 = osdate(y_d,timestamp1)
      time2 = osdate(y_d,timestamp2)
    end
    if quarter == 3 then
      timestamp1 = ostime{year = year, month = 7, day = 1}
      timestamp2 = ostime{year = year, month = 9, day = 30}
      time1 = osdate(y_d,timestamp1)
      time2 = osdate(y_d,timestamp2)
    end
    if quarter == 4 then
      timestamp1 = ostime{year = year, month = 10, day = 1}
      timestamp2 = ostime{year = year, month = 12, day = 31}
      time1 = osdate(y_d,timestamp1)
      time2 = osdate(y_d,timestamp2)
    end
    return timestamp1,timestamp2,time1,time2
end

  --檢驗是否爲空
function _M:check_is_nil(parameter)
    if parameter == nil or parameter == "" then
      return true
    else
      return false
    end
end
  --計算每一年的第二週(避開第一週存在跨年的情況)
function _M:get_secondWeek(year)
    local w = tonum(osdate("%w",ostime{year = year,month = 1,day = 1}))
    return year,8-w
end


function _M:split_str(expresion,reps)
  local resultStrList = {}
    string.gsub(expresion,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
  return resultStrList
end

function _M:str_in_table(str,tb)
  for _, v in pairs(tb) do
      if v == str then
          return true
      end
  end
  return false
end

function _M:tab(key,start)
      local funTable = {
    ["getTable"] = {
        ["Y"] = {"Q","M","W","D"},
        ["Q"] = {"M","W","D"},
        ["M"] = {"W","D"},
        ["W"] = {"D"},
        ["D"] = {"H"},
        ["H"] = {"N"},
        ["N"] = {"S"},
        ["S"] = {}
    }
}
return funTable[key][start]
end

function _M:err (msg)
  local err_msg = {
    ["scope_err"] = "超出範圍",["hour_err"] = "請指定該表達式的父約束(小時)",
    ["minute_err"] = "請指定該表達式的父約束(分鐘)", ["limit_err"] = "超出範圍限制",
    ["sign_err"] = "不符合規則的運算符號",["operationNum_err"] = "運算的數值不能爲空",
    ["constraint_err"] = "約束數值错误",["parameter_err"] = "請檢查參數是否符合解析要求",
    ["parameterNull_err"] = "參數不能爲空",["time_err"] = "結束時間不能小於開始時間",
    ["basetime_err"] = "傳入的基準時間需要不能为空",["expresion_err"] = "傳入表達式不需要再傳入其他參數"
  }
return err_msg[msg]
end

return _M