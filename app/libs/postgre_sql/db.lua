--[[ 
   操作postgresql的工具类
]]--

local sgsub = string.gsub
local tinsert = table.insert
local type = type
local ipairs = ipairs
local pairs = pairs
local pgsql = require("resty.postgres")
local cjson = require("cjson")
local nkeys = require("table.nkeys")
local t_new= table.new
local t_concat=table.concat
local start_mode = 'config-debug'

if ngx.shared.config then
    start_mode = ngx.shared.config:get("config")
end

local config = require("app.config.".. start_mode)
local DB = {}

function DB:new(conf)
    conf = conf or config.pgsql
    local instance = {}
    instance.conf = conf
    setmetatable(instance, { __index = self})
    return instance
end

-- INSERT INTO "public".users (id,name) VALUES (nextval
-- ('public.users_id_seq'),'黄') RETURNING id; 
-- 注意,postgresql通过对于序列操作的select并返回相对应的id
-- 且mysql在设置的时候，假如设置主健，就可以返回相对应的插入的id，但是postgresql并不是如此

function DB:exec(sql,not_log)
    -- ngx.log(ngx.ERR,sql)
    if not sql then
        ngx.log(ngx.ERR, "sql parse error! please check")
        return nil, "sql parse error! please check"
    end

    local conf = self.conf
    local db, err = pgsql:new()
    if not db then
        ngx.say("failed to instantiate pgsql: ", err)
        return
    end

    db:set_timeout(conf.timeout) -- 1 sec

    local ok, err, errno, sqlstate = db:connect(conf.connect_config)
    
    if not ok then
        ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
        return
    end

    --这个参数可传，可不传，当不为1的时候，才打日志
    if not_log~=1 then
        ngx.log(ngx.ERR,"sql:", sql)
    end

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

function DB:multi_exec(sql,not_log)

    local arr_res = {}

    if not sql then
        ngx.log(ngx.ERR, "sql parse error! please check")
        return nil, "sql parse error! please check"
    end

    local conf = self.conf
    local db, err = pgsql:new()
    if not db then
        --ngx.say("failed to instantiate pgsql: ", err)
        return
    end
    db:set_timeout(conf.timeout) -- 1 sec

    local ok, err, errno, sqlstate = db:connect(conf.connect_config)
    if not ok then
        ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
        return
    end
    
    if not_log~=1 then
        ngx.log(ngx.DEBUG,"sql:", sql)
    end

    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    end

    arr_res[1] = res
    local errcode
    local i = 2
    while err == "again" do
        res, err, errcode, sqlstate = db:read_result()
        if not res then
            ngx.log(ngx.ERR, "bad result #", i, ": ", err, ": ", errcode, ": ", sqlstate, ".")
        end

        arr_res[i] = res
        i = i + 1
    end

    local ok, err = db:set_keepalive(conf.pool_config.max_idle_timeout, conf.pool_config.pool_size)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
    end


    return arr_res, err, errno, sqlstate
end


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

function DB:multi_query(sql,params,not_log)
    if not params or is_array(params) then
        sql = self:parse_sql(sql, params)
    else
        sql = self:parse_sql_bind_params(sql, params)
    end
    return self:multi_exec(sql,not_log)
end

function DB:query(sql, params,not_log)
    if not params or is_array(params) then
        sql = self:parse_sql(sql, params)
    else
        sql = self:parse_sql_bind_params(sql, params)
    end
    return self:exec(sql,not_log)
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
        local t_cnt=cnt+cnt+1
        local tab=t_new(t_cnt,0)

        for i=1,t_cnt do
            if i%2==0 then
                tab[i]=params[i/2]
            else
                tab[i]=t[(i+1)/2]
            end
        end

        local sql=t_concat(tab)

        return sql

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

--分解出相应的字符串和参数
function DB:parse_sql(sql, params,flag)

    if not params or not table_is_array(params) or #params == 0 then
        ngx.log(ngx.DEBUG, "------ params err: ", cjson.encode(params))
        return sql
    end
    
    local new_params = {}

    local _, cnt = ngx.re.gsub(sql, [[\?]], '')
    
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
    
    local t = split(sql,"?")

    local sql=''

    if t==nil or params==nil or type(t)~="table" or type(params)~="table" then
        return nil
    end

    sql = compose(t, new_params,cnt)
   

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

function DB:concat_str(sql,num,str)
    local tab=t_new(num,0)

    for i=1,num do
        tab[i]=str
    end
    
    local str=t_concat(tab,',')
    
    local sql=sql..str
    return sql
    
end

return DB
