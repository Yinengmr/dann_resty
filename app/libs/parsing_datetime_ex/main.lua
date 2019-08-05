local ssub = string.sub
local smatch = string.match
local slen = string.len
local supper = string.upper
local tonum = tonumber
local osdate = os.date
local ostime = os.time
local comon = require("app.libs.parsing_datetime_ex.comon")
local time_num = require("app.libs.parsing_datetime_ex.num")
local conversion = require("app.libs.parsing_datetime_ex.conversion")
local variable = "([YQMWDHNS]%d*)"
local _M = {}
local cjson = require("cjson")

--加減運算
local function operation(head,value,num,basetime)
  local time = value.from
  local values,err = conversion:conversionTime(head,num,time,basetime)
  return values,err
end

--冒號運算
local function mathematical(head_str,parameter,value,basetime)
  local time = value.from
  local values = nil
  local err = nil
  local num,err= time_num:constant(head_str,parameter,basetime)
  if num == nil then
    return num,err
  end
  if head_str == "W" then
    num = num - 2
  else
    num = num - 1
  end
  local values,err = conversion:conversionTime(head_str,num,time,basetime)
  return values,err
end

--單字段運算
local function transform(start,datedata,basetime)
  local time = nil
  if start == "N" then
    return nil,comon:err("hour_err")
  elseif start == "S" then
     return nil,comon:err("minute_err")
  end
  local num,err= time_num:constant(start,datedata,basetime)
  if num == nil then
    return num,err
  end

  local values,err = conversion:conversionTime(start,num,time,basetime)
  return values,err
end

--拆分後續字段(運算符及其後續字段)
local function split_next(start,datedata,value,index,basetime)
  index = index + 1
  local len = slen(datedata)
  local head = start
  local begin = ssub(datedata,index,index)
  local values = nil
  local err = nil
  local head_str = nil

  if not comon:check_operation(begin) then
    return nil,comon:err("sign_err")
  end

  if begin == "+" or begin == "-" then
    local num = smatch(datedata, begin.."(%d*)")

    if comon:check_is_nil(num) then
      return nil,comon:err("operationNum_err")
    end
    num = begin..tonum(num)
    if begin == "-"  then
        index = index + slen(num) - 1
    else
        index = index + slen(num)
    end
    values = operation(head,value,num,basetime)
    head_str = head
  end

  if begin == ":" then
    local parameter = smatch(datedata,":"..variable,index)
    if comon:check_is_nil(parameter) then
      return nil,comon:err("constraint_err")
    end
    head_str = ssub(parameter,1,1)
    index = index + slen(parameter)
    if not comon:str_in_table(head_str,comon:tab("getTable",head)) then
      return nil,comon:err("limit_err")
    end
      values,err = mathematical(head_str,parameter,value,basetime)
  end

  if comon:check_is_end(index,len) then
    return values,err
  end
  return split_next(head_str,datedata,values,index,basetime)
end

--分析數據第一個字符
local function split_first(datedata,basetime)
  local len = slen(datedata)
  local parameter = smatch(datedata,variable)
  if comon:check_is_nil(parameter) then
      return nil,comon:err("parameter_err")
  end
  local start = ssub(parameter,1,1)
  local index = slen(parameter)
  local value = nil
  local err = nil
  value,err = transform(start,datedata,basetime)
  if not value then
    return value,err
  end
  if comon:check_is_end(index,len) then
    return value,err
  end
  return split_next(start,datedata,value,index,basetime)
end

--判斷表達式主體
function _M:TimeConvert(expresion,start_time,stop_time,basetime)
  local time_change = {}
--分割表達式
  if not comon:check_is_nil(expresion) then
     local  str_table = comon:split_str(expresion,",")
     start_time = str_table[1]
     stop_time = str_table[2]
  end

  if comon:check_is_nil(start_time) then
    return nil,comon:err("parameterNull_err")
  end
  --basetime可以爲nil,但不可以爲" "
  if basetime == "" then
    return nil,comon:err("basetime_err")
  end

  local start_timeA = supper(start_time)
  local stop_timeA = nil
  if not comon:check_is_nil(stop_time) then
    stop_timeA = supper(stop_time)
  end

  if comon:check_is_nil(stop_time) then
    return split_first(start_timeA,basetime)
  end

  local firstdata,err = split_first(start_timeA,basetime)
  if not firstdata  then
    return firstdata,err
  end

  local from = firstdata.from
  local from_str = firstdata.from_str   ----
  local nextdata,err = split_first(stop_timeA,basetime)
  
  if not nextdata  then
    return nextdata,err
  end

  local to = nextdata.to
  local to_str = nextdata.to_str       ----
  if comon:check_is_nil(from,to) then
    return nil,comon:err("parameter_err")
  end

  if from > to then
    return nil,comon:err("time_err")
  end

    time_change.from = from
    time_change.to = to
    time_change.from_str = from_str
    time_change.to_str = to_str
    return time_change
end
return _M
