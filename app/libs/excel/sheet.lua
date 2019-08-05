local utils = require("app.libs.utils")
local cjson = require("cjson")
local tb_max = table.maxn
local _M = {}
-- option = { head: start =1, row=2 , key_map, data: start = 4}
-- function _M:table_add(a,b)
--     local t = {}
--     local t1 = a
--     local t2 = b
--     t._add = function(t1,t2)
        
--     end
--     local result = t1+t2

--     -- setmetatable(t, { __index = self})
--     return result
-- end


function _M:new(sheet_json)
    local instance = {}
    instance.head = sheet_json[1]
    table.remove( sheet_json, 1)
    instance.data = sheet_json
    setmetatable(instance, { __index = self})
    return instance
end

--智能商務系統專用
function _M:new1(sheet_json)
    local instance = {}
    local t3 = {}
    for i= 1, tb_max(sheet_json[1]) do
        for j=1,tb_max(sheet_json[2]) do
             if i == j then
                t3[i] =  sheet_json[1][i]..' '..sheet_json[2][j]
             end
        end
    end
    instance.head = t3
    instance.first = sheet_json[1]
    instance.second = sheet_json[2]
    instance.third = sheet_json[3]
    table.remove( sheet_json, 1)
    table.remove( sheet_json, 1)
    table.remove( sheet_json, 1)
    instance.data = sheet_json
    setmetatable(instance, { __index = self})
    return instance
end

function _M:get_header()
    return self.head
end

function _M:get_data()
    return self.data
end

function _M:set_header_map(header_map)
    if type(header_map) ~= 'table'  then
        return false,'header_map 必须为table'
    end
    local head_keys = {}
    local head_data_map = {}
    --检查map合法性,是否在header中存在
    for k,v in pairs(header_map) do
        local exist = false
        for kk,vv in pairs(self:get_header()) do
            if vv == v then
                table.insert( head_keys, k )
                head_data_map[k] = kk
                exist = true
                break
            end
        end
        if not exist then
            return false,v .. '在头部不存在'
        end
    end
    self.head_map_keys = head_keys
    self.header_map = head_data_map
    return true
end

function _M:header_verify(fun_header_ver)
    fun_header_ver(self:get_header())
end

function _M:get_map_data(val,val_keys)
    -- 头部映射检查
    if not self.head_map_keys then
        return false,'未设置header_map'
    end
    -- 检查val_keys合法性
    if type(val_keys) ~= 'table' then
        return false,'val_keys必须为table类型'
    end
    for _,v in pairs(val_keys) do
        if not utils.str_in_table(v,self.head_map_keys) then
            return false,'传入的key必须在head_map中存在'
        end
    end

    local vals = {}
    for _,v_map in pairs(val_keys) do
        local val_item = {
            key = v_map,
            data = val[self.header_map[v_map]]
        }
        table.insert( vals, val_item)
    end

    return vals

end

-- 空值检查
function _M:chk_null(v,vals_keys,success_cb,false_cb)
    local success_val = {}
    local false_val = {}
    local is_success = true
    local vals,err = self:get_map_data(v,vals_keys)
    if not vals then
        return false,err
    end
    for _,v in pairs(vals) do
        if utils.chk_is_null(v.data) then
            is_success = false
            table.insert( false_val, v)
        else
            table.insert( success_val, v )
        end
    end
    if is_success then
        if success_cb then
            success_cb(success_val)
        end       
    else
        if false_cb then
            false_cb(false_val)
        end
    end
    return true
end

-- 格式检查
function _M:chk_format(v,vals_keys,format,success_cb,false_cb)
    local success_val = {}
    local false_val = {}
    local is_success = true

    if type(format) ~= 'string' then
        return false,'format必须为字符串格式'
    end
    local vals,err = self:get_map_data(v,vals_keys)
    if not vals then
        return false,err
    end

    for _,v in pairs(vals) do
        local res = ngx.re.match(v.data,format)
        if not res then
            is_success = false
            table.insert( false_val, v)
        else
            table.insert( success_val, v )
        end
    end

    if is_success then
        if success_cb then
            success_cb(success_val)
        end       
    else
        if false_cb then
            false_cb(false_val)
        end
    end
    return true
end

-- 存在检查
function _M:chk_str_in_table(v,vals_keys,chk_table,success_cb,false_cb)
    local success_val = {}
    local false_val = {}
    local is_success = true
    local vals,err = self:get_map_data(v,vals_keys)
    if not vals then
        return false,err
    end
    for _,v in pairs(vals) do
        if not utils.str_in_table(v.data,chk_table) then
            is_success = false
            table.insert( false_val, v)
        else
            table.insert( success_val, v )
        end
    end
    if is_success then
        if success_cb then
            success_cb(success_val)
        end       
    else
        if false_cb then
            false_cb(false_val)
        end
    end
    return true
end

-- 數字检查
function _M:chk_number(v,vals_keys,success_cb,false_cb)
    local success_val = {}
    local false_val = {}
    local is_success = true
    local vals,err = self:get_map_data(v,vals_keys)
    if not vals then
        return false,err
    end
    for _,v in pairs(vals) do
        if not tonumber(v.data) then
            is_success = false
            table.insert( false_val, v)
        else
            table.insert( success_val, v )
        end
    end
    if is_success then
        if success_cb then
            success_cb(success_val)
        end       
    else
        if false_cb then
            false_cb(false_val)
        end
    end
    return true
end

-- function _M:add_verify(val_keys,func,success_cb,false_cb)
--     -- 头部映射检查
--     if not self.head_map_keys then
--         return false,'未设置header_map'
--     end
--     -- 检查val_keys合法性
--     if type(val_keys) ~= 'table' then
--         return false,'val_keys必须为table类型'
--     end
--     for _,v in pairs(val_keys) do
--         if not utils.str_in_table(v,self.head_map_keys) then
--             return false,'传入的key必须在head_map中存在'
--         end
--     end

--     -- 检查fun合法性
--     if not (type(func) == 'string' and self.chk_funs[func] ~= nil) or 
--        not type(func) == 'function' then
--         return false,'func错误'
--     end

--     --数据检查
--     for k,v in pairs(self.data) do
--         -- 数据映射
--         local vals = {}
--         for _,v_map in pairs(val_keys) do
--             ngx.log(ngx.ERR,v_map)
--             local val_item = {
--                 row = k,
--                 key = v_map,
--                 data = v[self.header_map[v_map]]
--             }
--             table.insert( vals, val_item)
--         end
--         --调用方法检查
--         if type(func) == 'string' then
--             self.chk_funs[func](vals,success_cb,false_cb)
--         end
--     end

-- end

-- function _M:data_verify(val_keys,func,success_cb,false_cb)
--     --数据检查
--     for k,v in pairs(self.data) do
--         -- 数据映射
--         local vals = {}
--         -- for _,v_map in pairs(val_keys) do
--         --     ngx.log(ngx.ERR,v_map)
--         --     local val_item = {
--         --         row = k,
--         --         key = v_map,
--         --         data = v[self.header_map[v_map]]
--         --     }
--         --     table.insert( vals, val_item)
--         -- end
--         --调用方法检查
--         if type(func) == 'string' then
--             self.chk_funs[func](vals,success_cb,false_cb)
--         end
--     end
-- end

return _M