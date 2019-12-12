local cjson   = require("cjson")
local utils   = require("app.libs.utils")
local ngx_re = require "ngx.re"


local config = require("app.config.".. ngx.shared.config:get("config"))

local ngx_log = ngx.log

ngx_log(ngx.DEBUG, "访问阶段IP限制访问")

ngx.print(ngx.var.remote_addr)
ngx.print(' 该IP无权访问此系统，请联系 22132')
--[[ 
    记录IP 

 ]]