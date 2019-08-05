local type  = type
local pairs = pairs
local mceil = math.ceil
local mfloor  = math.floor
local mrandom = math.random
local mmodf   = math.modf
local ssub  = string.sub
local sgsub = string.gsub
local tinsert = table.insert
local rinsert = table.remove
local str  = require "resty.string"
local date = require("app.libs.date")
local resty_sha256 = require "resty.sha256"
local lfs = require ("lfs")
local _M = {}
local utils = _M


function _M.encode(s)
    local sha256 = resty_sha256:new()
    sha256:update(s)
    local digest = sha256:final()
    return str.to_hex(digest)
end


--当前时间字符串
function _M.now()
    local n = date()
    local result = n:fmt("%Y-%m-%d %H:%M:%S")
    return result
end


--去除前后的空字符
function _M.trim(str)

    if type(str) == "string" then
        local s = sgsub(str,"^%s*(.-)%s*$","%1")
        return s
    end
end


--分裂一个字符串，指定分裂的字符
function _M.string_split(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end

    local delimiter_r = string.match(str .. delimiter,delimiter)
    
    local result = {}
    for match in (str .. delimiter_r):gmatch("(.-)" .. delimiter) do
        tinsert(result, match)
    end

    return result
end


--是一个空表
function _M.is_table_empty(t)
    if t == nil or _G.next(t) == nil then
        return true
    else
        return false
    end
end


--是下个数组
function _M.table_is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    --[[
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    --]]
    return true
end


--字符串在表中
function _M.str_in_table(str,tb)  -- 10  {123,10,12} {gt = 10,hy = 132}
    for _, v in pairs(tb) do
        if v == str then
            return true
        end
    end
    return false
end


--字符串转成表
function _M.str_to_table(str)
    if str == nil or type(str) ~= "string" then
        return
    end

    return loadstring("return " .. str)()
end

function _M.str_escape_by_json(str)

    local func = function (m)
        return "\\x"..string.format("%02x", m[0]:byte(1))
    end
    
    local re_str = "["..[[\x00-\x1f\x22\x2f\x39\x5c\x7f]] .. "]"
  --local re_str = "["..[[\x00-\x07\b\t\n\x0b\f\r\x0e-\x1f\x22\x2f\x39\x5c\x7f]] .. "]"

    local newstr, n, err = ngx.re.gsub(str, re_str, func, "i")

    return newstr
end

--从表中移出某一个项目
function _M.remove_item_by_table(key,tb)
    local tmp ={}

    --把每個key做一個下標，保存到臨時的table中，轉換成{1=a,2=c,3=b}
    --組成一個有順序的table，才能在while循環準備時使用#table
    for i in pairs(tb) do
        tinsert(tmp, i)
    end

    local newTb = {}
    --使用while循環剔除不需要的元素
    local i = 1
    while i <= #tmp do
        local val = tmp [i]
        if val == key then
            --如果是需要剔除則remove
            rinsert(tmp, i)
         else
            --如果不是剔除，放入新的tab中
            newTb[val] = tb[val]
            i = i + 1
         end
     end

    return newTb
end


--转成字符串
function _M.to_string_ex(value)

    if  type(value) == 'table' then
       return _M.table_to_str(value)
    end

    if  type(value) == 'string' then
        return "\'" .. value .. "\'"
    end

    return tostring(value)
end


--将表转成字符串
function _M.table_to_str(t)

    if t == nil then 
        return "" 
    end
    
    local retstr= ""

    local i = 1
    for key, value in pairs(t) do
        
        local signal = ","

        if i == 1 then
          signal = ""
        end

        if key == i then
            retstr = retstr .. signal .. _M.to_string_ex(value)
        else
            if type(key) == 'number' or 
               type(key) == 'string' then
                retstr = retstr .. signal .. '[' .. _M.to_string_ex(key) .. "]=" .. _M.to_string_ex(value)
            else
                if type(key) == 'userdata' then
                    retstr = retstr .. signal .. "*s" .. _M.table_to_str(getmetatable(key)) .. "*e".. "=" .. _M.to_string_ex(value)
                else
                    retstr = retstr .. signal .. key .. "=" .. _M.to_string_ex(value)
                end
            end
        end

        i = i + 1
    end

    return retstr .. ""
end


--检查是否为空
function _M.chk_is_null(...)

    local is_null = false
    local len = select('#',...)
    
    --for k,v in pairs({...}) do
    for k=1, len do
        local v = select(k,...)
        if v == nil      or
           not v         or
           v == ngx.null or
           v == "" then
            is_null  = true
            break;
        end
    end

    return is_null
end


--检查文件是否存在
function _M.file_exists(path)
    local flag = false
    local file = io.open(path, "r")

    if file then
        io.close(file)
        flag = true
    end
    
    return flag
end

function _M.file_size(path)
    local file = io.open(path,"r")
    
    if file then
        local file_size = file:seek("end")
        io.close(file)
        return file_size
    end

    return 0
end

function _M.file_remove(path)
    return os.remove(path)
end

function _M.file_content(path)
    
    local file = io.open(path,"r")
    local content = file:read("*a")
    io.close(file)
    
    return content
end

function _M.dir_exists(path)
    return utils.file_exists(path)
end


function _M.batch_mkdir(path)

    local separator = "/"
    local paths = utils.string_split(path, separator)

    local curr = paths[1]
    for i=2, #paths, 1 do
        
        curr = curr .. separator .. paths[i]
        if not utils.dir_exists(curr) then
            local res , err = lfs.mkdir(curr)
            if not res and b ~= 'File exists' then
                return false, err
            end
        end
    end

    return true, nil
end


function _M.upd_param(data, match_tb)

    local pos_param = ""

    if (match_tb == nil or type(match_tb) ~= "table") then
        return nil;
    end

    for key, val in pairs(data) do

        local tmp = match_tb[key]

        if tmp ~= nil then
            if (type(val) == "string") then
                pos_param = pos_param .. ", " .. tmp .. "= " .. ngx.quote_sql_str(val)
            else
                pos_param = pos_param .. ", " .. tmp .. "= " .. val
            end
        end
    end

    if #pos_param ~= 0 then
        pos_param = ssub(pos_param,2)
    end

    return pos_param

end

return _M
