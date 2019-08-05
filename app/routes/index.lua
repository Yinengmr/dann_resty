local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")


local start_mode = ngx.shared.config:get("config") 
local config = require("app.config.".. start_mode)
local menu_config = config.menu

local lor = require("lor.index")
local _M = lor:Router()


_M:get("", function(req, res, next)
     ngx.say('hi')
     res:render('index/index')
end)


return _M