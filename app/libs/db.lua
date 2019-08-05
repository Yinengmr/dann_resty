local sgsub = string.gsub
local tinsert = table.insert
local type = type
local ipairs = ipairs
local pairs = pairs
local mysql = require("resty.mysql")
local cjson = require("cjson")
local t_new= table.new
local t_concat=table.concat
   
local start_mode = 'config-dev'

if ngx.shared.config then
    start_mode = ngx.shared.config:get("config")
end

local config = require("app.config.".. start_mode)
local DB = {}

function DB:new(conf)
    conf = conf or config.mysql
    local instance = {}
    instance.conf = conf
    setmetatable(instance, { __index = self})
    return instance
end

function DB:exec(sql)
    if not sql then
        ngx.log(ngx.ERR, "sql parse error! please check")
        return nil, "sql parse error! please check"
    end

    local conf = self.conf
    local db, err = mysql:new()
    if not db then
        --ngx.say("failed to instantiate mysql: ", err)
        return
    end
    db:set_timeout(conf.timeout) -- 1 sec

    local ok, err, errno, sqlstate = db:connect(conf.connect_config)
    if not ok then
        --ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
        return
    end

    ngx.log(ngx.DEBUG, "connected to mysql, reused_times:", db:get_reused_times(), " sql:", sql)

    db:query("SET NAMES utf8mb4")
    db:query("set character_set_client=utf8mb4")
    db:query("set character_set_results=utf8mb4")
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    end

    local ok, err = db:set_keepalive(conf.pool_config.max_idle_timeout, conf.pool_config.pool_size)
    if not ok then
        --ngx.say("failed to set keepalive: ", err)
    end

    return res, err, errno, sqlstate
end

function DB:multi_exec(sql)

    local arr_res = {}

    if not sql then
        ngx.log(ngx.ERR, "sql parse error! please check")
        return nil, "sql parse error! please check"
    end

    local conf = self.conf
    local db, err = mysql:new()
    if not db then
        --ngx.say("failed to instantiate mysql: ", err)
        return
    end
    db:set_timeout(conf.timeout) -- 1 sec

    local ok, err, errno, sqlstate = db:connect(conf.connect_config)
    if not ok then
        --ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
        return
    end

    ngx.log(ngx.DEBUG, "connected to mysql, reused_times:", db:get_reused_times(), " sql:", sql)

    db:query("SET NAMES utf8mb4")
    db:query("set character_set_client=utf8mb4")
    db:query("set character_set_results=utf8mb4")
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    end

    --//////////////////////////////////////

    arr_res[1] = res
    --ngx.say("result #1: ", cjson.encode(res)," err:",err," errno:",errno," sqlstate:",sqlstate)
    local errcode
    local i = 2
    while err == "again" do
        res, err, errcode, sqlstate = db:read_result()
        if not res then
            ngx.log(ngx.ERR, "bad result #", i, ": ", err, ": ", errcode, ": ", sqlstate, ".")
        end

        --ngx.say("result #", i, ": ", cjson.encode(res)," err:",err," errno:",errno," sqlstate:",sqlstate)
        arr_res[i] = res
        i = i + 1
    end

    --/////

    local ok, err = db:set_keepalive(conf.pool_config.max_idle_timeout, conf.pool_config.pool_size)
    if not ok then
        --ngx.say("failed to set keepalive: ", err)
    end

    --ngx.say(cjson.encode(arr_res));

    return arr_res, err, errno, sqlstate
end

function DB:isData(result)

end
--[[
local function is_array(t)
    if type(t) ~= 'table' then 
        return false
    end
    local i = 0
    for k,_ in pairs(t) do
        i = i + 1
        if k ~= i then
            return false
        end
    end
    return true
end
]]

local function is_array(t)
    if type(t) ~= 'table' then 
        return false
    end
    for k,_ in pairs(t) do
        if type(k) ~= 'number' then
            return false
        end
    end
    return true
end

function DB:multi_query(sql,params)
    if not params or is_array(params) then
        sql = self:parse_sql(sql, params)
    else
        sql = self:parse_sql_bind_params(sql, params)
    end
    return self:multi_exec(sql)
end

function DB:query(sql, params)
    if not params or is_array(params) then
        sql = self:parse_sql(sql, params)
    else
        sql = self:parse_sql_bind_params(sql, params)
    end
    return self:exec(sql)
end

function DB:select(sql, params)
    return self:query(sql, params)
end

function DB:insert(sql, params)
    local res, err, errno, sqlstate = self:query(sql, params)
    if res and not err then
        return  res.insert_id, err
    else
        return res, err
    end
end

function DB:update(sql, params)
    return self:query(sql, params)
end

function DB:delete(sql, params)
    local res, err, errno, sqlstate = self:query(sql, params)
    if res and not err then
        return res.affected_rows, err
    else
        return res, err
    end
end

local function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        tinsert(result, match)
    end
    return result
end

local function compose(t, params,cnt)
    if t==nil or params==nil or type(t)~="table" or type(params)~="table" or #t~=#params+1 or #t==0 then
        return nil
    else
        local t_cnt=cnt+cnt+1
        local tab=t_new(t_cnt,0)

        for i=1,t_cnt do
            if i%2==0 then
                tab[i]=params[i/2]
            else
                tab[i]=t[(i+1)/2]
            end
        end
        
        local result=t_concat(tab)
        -- local result = t[1]
        -- for i=1, #params do
        --     result = result  .. params[i].. t[i+1]
        -- end

        return result
    end
end

local function table_is_array(t)
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

function DB.upd_param(data, match_tb)

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

function DB:parse_sql(sql, params)
    if not params or not table_is_array(params) or #params == 0 then
        ngx.log(ngx.DEBUG, "------ params err: ", cjson.encode(params))
        return sql
    end
    
    local new_params = {}
    --ngx.log(ngx.ERR, "------ wait params: ", cjson.encode(params)," cnt: ",#params)

    local _, cnt = ngx.re.gsub(sql, [[\?]], '')
    
    --for  i=1,#params do
    for  i=1,cnt do

        local v = params[i] 
        if v and type(v) == "string" then
            v = ngx.quote_sql_str(v)
        end

        if not v then
            v = 'null'
        end

        tinsert(new_params, v)
    end

    --if #params < cnt then
    --    for i = #params + 1, cnt do
    --        tinsert(new_params, 'null')
    --    end
    --end

    --ngx.log(ngx.ERR, "------ new params: ", cjson.encode(new_params)," cnt: ",#new_params)
    local t = split(sql,"?")
    --ngx.log(ngx.ERR, "------ parse_sql: ", sql, " t: ", cjson.encode(t), " new_params : ", cjson.encode(new_params) ,".")

    local sql = compose(t, new_params,cnt)
    
    --ngx.log(ngx.ERR, "------   new_sql: ", sql ," .")
    
    return sql
end

function DB.sql_fuzzy_query(sql, params, value, is_direct)
    if is_direct then
        sql = sql .. ' WHERE '
    else 
        sql = sql .. ' AND '
    end
    sql = sql .. 'instr(CONCAT_WS(\',\',  '
    for k,v in pairs(params) do
        if k > 1 then
            sql = sql .. ' , '
        end
        sql = sql .. v 
    end
    sql = sql .. ') , \'' .. value .. '\') > 0 ' 
    return sql
end

function DB:parse_sql_bind_params(sql, params)
    local new_params = {}
    for  k, v in pairs(params) do
        local val = v
        if v and type(v) == "table"  then
            if v.flag == "raw" then
            val = v.value
            end
        end

        if v and type(v) == "string" then
            val = ngx.quote_sql_str(v)
        end

        if not v then
            val = 'null'
        end

        new_params[k] = val
    end

    local regex = [[(?<str>:(?<param>([1-9]|[a-z]|[A-Z]|_){1,}))]]
    local it,err = ngx.re.gmatch(sql,regex)
    if not it then
        ngx.log(ngx.ERR, "gmatch error: ", err)
        return
    end
    local parse_params = {}

    while true do
        local m, err = it()
        if err then
            ngx.log(ngx.ERR, "gmatch error: ", err)
            return
        end
   
        if not m then
            break
        end
   
        -- found a match
        table.insert( parse_params, {str = m['str'],val = m['param']} )
    end
    
    for _,v in pairs(parse_params) do
        local newstr, n, err = ngx.re.gsub(sql, v['str'], 
                               new_params[v['val']] or ngx.quote_sql_str('null'), "u")
        if newstr then
            sql = newstr
        else
            ngx.log(ngx.ERR, "error: ", err)
            return
        end
    end

    return sql
   
end

return DB
