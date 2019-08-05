local ssub = string.sub
local sgsub = string.gsub
local smatch = string.match
local sfind = string.find
local tonum = tonumber
local osdate = os.date
local ostime = os.time
local comon = require("app.libs.parsing_datetime_ex.comon")
local variable = "([YQMWDHNS]%d*)"
local _M = {}
local scopeTable = {
  ["Y"] = { max = 9999, exp ="%Y"}, ["Q"] = { max = 4,  exp = "%m"},
  ["M"] = { max = 12, exp = "%m"},  ["H"] = { max = 23, exp = "%H"},
  ["W"] = { max = 53, exp = "%W"},  ["D"] = { max = 366, exp ="%j"},
  ["N"] = { max = 59, exp = "%M"},  ["S"] = { max = 59, exp = "%S"}
}

function _M:judge(osdate_expression,subvalue,time_stamp)
  local number = tonum(osdate(osdate_expression,time_stamp))
  if subvalue == "Q" then
   return comon:check_quarter(number)
  end
  if subvalue == "W" then
      return number + 1
  end
  if subvalue == "H" then
      return number + 1
  end
  return number
end

--将传过来常量的转换为所需的number
function _M:constant(start,datedata,basetime)
  local _,times = sgsub(datedata,start.."%d*","%1")
  if times == 0 or times > 1 then
     return nil,comon:err("scope_err")
  end
  local value = smatch(datedata,variable)
  local subvalue = start
  local i,j = sfind(datedata,value)
  local min = 1
  if subvalue == "H" or subvalue == "N" or subvalue == "S" then
    min = 0
  end
  local max = scopeTable[subvalue].max
    if i == j then
      local osdate_expression = scopeTable[subvalue].exp
      if basetime then
        return _M:judge(osdate_expression,subvalue,basetime)
      end
        return _M:judge(osdate_expression,subvalue,os.time())
     end
    local size = tonum(ssub(datedata,i+1,j))
    if size < min or size > max then
      return nil,comon:err("scope_err")
    end
    if subvalue == "H" or subvalue == "N"  or subvalue == "S" then
      return size + 1
    end
    return size
end
return _M