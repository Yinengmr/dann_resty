local cjson   = require("cjson")
local utils   = require("app.libs.utils")
local ngx_re = require "ngx.re"


local config = require("app.config.".. ngx.shared.config:get("config"))

local ngx_log = ngx.log

local redis = require("resty.redis")

local timeout = config.redis.timeout
local host = config.redis.connect_config.host
local port = config.redis.connect_config.port
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size = config.redis.pool_config.pool_size

local time = ngx.time()
local os_time = os.time

local _M= {}

function _M:get_key()
    ngx.update_time()
    

    --redis on
    local red = redis:new()
    red:set_timeout(timeout)

    local ok, err = red:connect(host,port)
    if not ok or err then
        return nil, err;
    end
    -- 随机口令
    -- local str = math.random(10,99)..string.char(math.random(97,122))..math.random(0,9)


    local k = os.date("%Y-%m-%d-%H", os_time())
    k = math.floor((ngx_re.split(k,'-')[1] + ngx_re.split(k,'-')[2] 
        + ngx_re.split(k,'-')[3] + ngx_re.split(k,'-')[4])*0.6 
        + ngx_re.split(k,'-')[4])..string.char(97+ ngx_re.split(k,'-')[4])
    red:set('key',str)
    local key = red:get('key')
    ngx_log(ngx.ERR, "生成抽签口令\""..k.."\"")

    --redis off 
    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    
    if not ok or err then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return
    end


    local key = _M
    local ok, err = ngx.timer.at(60*30, key.get_key,key)
    if not ok then
        ngx_log(ngx.ERR, "failed to create the timer: ", err)
        return
    end 

end
return _M