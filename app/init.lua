--JIT调式
--local v = require "jit.v"
--v.on("/tmp/dump")

--JIT DUMP
--local dump = require "jit.dump"
--dump.on(nil, "/tmp/dump")

require "resty.core" -- 确保 lua-resty-core 是启用的

--nginx 服务起动方式
local process = require "ngx.process"
local type = process.type()
ngx.log(ngx.DEBUG, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~", type)

--nginx 服务起动参数
local ffi = require "ffi"

ffi.cdef[[
int     ngx_argc;
char    **ngx_argv;
]]

local config_val = 'dev'
for i = 0, ffi.C.ngx_argc -1 do
    
    ngx.log(ngx.DEBUG, ffi.string(ffi.C.ngx_argv[i]))
    
    local val = ffi.string(ffi.C.ngx_argv[i])
    -- regex = [[^conf\/nginx-(([a-z])+).conf]]
    
    local regex = [[^conf\/nginx-(([a-z]|[0-9]|\-)+).conf]]
    local tmp   = ngx.re.match(val, regex)

    if tmp then
        config_val = tmp[1]
        break;
    end
end

local config = ngx.shared.config

config:set("config", 'config-'..config_val)

local my_config = require("app.config.".. config:get("config"))


--local is_debug = os.getenv("is_debug");

-- ngx.log(ngx.DEBUG, is_debug )

 ngx.log(ngx.DEBUG, config:get("config") )

-- repl = require('resty.repl')
