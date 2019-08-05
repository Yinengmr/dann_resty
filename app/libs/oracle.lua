local sgsub = string.gsub
local tinsert = table.insert
local type = type
local ipairs = ipairs
local pairs = pairs
local luasql = require "luasql.oci8"
local cjson  = require("cjson")
local utils = require("app.libs.utils")

local config = require("app.config.".. ngx.shared.config:get("config"))

local io_mode = { input = 1, output = 2}

--[[
if ngx.shared.config then
    start_mode = ngx.shared.config:get("config")
end
]]

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 15)

_M.new_tab = new_tab
_M._VERSION = '0.01'

function _M:new(conf)
    conf = conf or config.oracle
    local instance = {}
    instance.conf = conf
    setmetatable(instance, { __index = self})
    return instance
end

function _M:exec(sql)
    if not sql then
        ngx.log(ngx.ERR, "sql parse error! please check")
        return nil, "sql parse error! please check"
    end

    local conf = self.conf
    local env, err =  assert(luasql.oci8())
    if not env then
        --ngx.say("failed to instantiate oracle: ", err)
        return
    end


    local con  = assert(env:connect(conf.sourcename, 
                                    conf.username,
                                    conf.password))
    if not con then
        --ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
        ngx.log(ngx.ERR,"failed to connect: ", con)
        return
    end

    local cur = con:execute(sql)

    local datas = {}
    local data = {}
    local idx = 1
    local row = nil

    if(cur ~=nil and type(cur) == 'number') then
        datas["insert_id"] = cur
    end

	if (cur ~= nil and type(cur) ~= 'number') then
	 row = cur:fetch({},"a"); 
	end

	while row do
		for k , v in pairs(row) do
		   data[k] = v;
		end

		datas[idx] = data;

		row = cur:fetch({},"a");
		data = {};
		idx = idx + 1;
	end

	if (cur ~= nil) then 
		cur:close()
	end 

	con:close() 
	env:close() 

	return datas
end

function _M:multi_exec(sql, params)

    local arr_res = {}

    if not sql then
        ngx.log(ngx.ERR, "sql parse error! please check")
        return nil, "sql parse error! please check"
    end

    local conf = self.conf
    local env = assert( luasql.oci8() );
    if not env then
        ngx.log(ngx.ERR,"failed to instantiate oracle: ", env)
        return
    end

    ngx.log(ngx.ERR,"show conf: ", cjson.encode(conf))
    
    local con = assert(env:connect(  conf.sourcename, 
                                     conf.username,
                                     conf.password))
    if not con then
        ngx.log(ngx.ERR, "failed to connect: ", con)
        return
    end

    local stmt = con:prepare(sql)

    for idx, param in ipairs(params) do 

        local io    = param["dio"]
        local dio   = self:get_io_mode(io)
        local len   = param["len"]
        local val   = param["val"]
        local typ   = param["typ"]
        local pos   = tonumber(param["pos"])

        if     typ == 'string' then
            stmt:bind_string(pos, val, dio)
            
        elseif typ == 'number' then
            stmt:bind_number(pos, tonumber(val), dio)
           
        elseif typ == 'cursor' then
            stmt:bind_cursor(pos, dio)
            
        else
            -- 哈也没有
        end
        
    end
    
    ngx.log(ngx.ERR, "------ ", sql, cjson.encode(params))

    local cur, err  = stmt:execute(sql)
    
    local idx = 1;
    local datas = {};
    local data = {};

    if(cur ~=nil and type(cur) == 'number') then
        datas["insert_id"] = cur
    end

    if(cur ~=nil and type(cur) ~= 'number') then
        local row = cur:fetch({},"a")  ---- 取出cursor中的数据,

        while row do
            for k , v in pairs(row) do
            data[k] = v;
            end
            datas[idx] = data
            row = cur:fetch({},"a");
            
            idx = idx + 1;
            data = {}
        end

        cur:close()
    end

    stmt:close() 
    con:close() 
    env:close() 

    return datas

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

function _M:multi_query(sql,params)
    
    if not params or is_array(params) then
        sql = self:parse_sql(sql, params)
    else
        sql, params  = self:parse_sql_bind_params(sql, params)
        return self:multi_exec(sql, params)
    end
    return self:exec(sql)
end

function _M:query(sql, params)
    if not params or is_array(params) then
        sql = self:parse_sql(sql, params)
    else
        sql, params = self:parse_sql_bind_params(sql, params)
        return self:multi_exec(sql, params)
    end
    return self:exec(sql)
end

function _M:select(sql, params)
    return self:query(sql, params)
end

function _M:insert(sql, params)
    local res, err, errno, sqlstate = self:query(sql, params)
    if res and not err then
        return  res.insert_id, err
    else
        return res, err
    end
end

function _M:update(sql, params)
    return self:query(sql, params)
end

function _M:delete(sql, params)
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

local function compose(t, params)
    if t==nil or params==nil or type(t)~="table" or type(params)~="table" or #t~=#params+1 or #t==0 then
        return nil
    else
        local result = t[1]
        for i=1, #params do
            result = result  .. params[i].. t[i+1]
        end
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

function _M:parse_sql(sql, params)
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


    local sql = compose(t, new_params)
    
    return sql
end

function _M.sql_fuzzy_query(sql, params, value, is_direct)
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

function _M:get_io_mode(str)
    return io_mode[str] or 1
end

function _M:parse_sql_bind_params(sql, params)
    --[[
        {
            fields = value,
            fields = { typ = 'cursor'/'string'/'number' ,
                       dio = 'in'/'out', 
                       len = n, 
                       val = value }
        }
        ]]
    -- (\:(?<var_name>([1-9]|[a-z]|[A-Z]|_)*))(?=([^\"']*[\"'][^\"']*[\"'])*[^\"']*$)
    
    local regex = [[(?<str>:(?<var_name>([1-9]|[a-z]|[A-Z]|_){1,}))]]
    local it,err = ngx.re.gmatch(sql,regex)
    
    if not it then
        ngx.log(ngx.ERR, "gmatch error: ", err)
        return sql , nil , err
    end

    local bind_params = {}

    local idx = 1
    while true do
        local m, err = it()
        if err then
            ngx.log(ngx.ERR, "gmatch error: ", err)
            return sql , nil , err
        end
   
        if not m then
            break
        end
   
        -- found a match
        local key = m['var_name']

        local val = nil
        local typ = 'string'
        local dio = 'input'
        local len = 0
        
        local param = params[key]
        if  type(param) == 'table' and not utils.chk_is_null(param,param.val)   then
            typ = param.typ or 'string'
            dio = param.dio or 'input'
            val = param.val or 'null'
            len = param.len or 0

            if  typ == 'cursor' then
                val = nil
            end
        end

        if param and (type(param) == 'string' or type(param) == 'number') then
            val = param
        end

        if not param then
            val = 'null'
        end

        if dio == 'output' then
            if typ == 'string' then 
                val = string.rep('a', len)
            end
        end

        table.insert( bind_params, {pos = idx  , val = val, typ = typ,
                                    dio = dio, len = len } )
        idx = idx + 1
    end
    
    return sql, bind_params
   
end

return _M
