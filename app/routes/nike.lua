local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")


local config = ngx.shared.config:get("config") 
local http = require("resty.http")
local zlib = require "zlib"

local lor = require("lor.index")
local _M = lor:Router()

--[[ 

主页 get http://hn.topsports.com.cn/asdf123zxc/phone/qh_xin.html?area_code=HN

获取品牌 post http://hn.topsports.com.cn/asdf123zxc/phone/DataSour.aspx?ID=10&addCode=HN 响应 NK,Jordan^NK,NK

发送身份证 post http://hn.topsports.com.cn/asdf123zxc/phone/DataSour.aspx?ID=4&userID=421126199503086619

获取主题 post http://hn.topsports.com.cn/asdf123zxc/phone/DataSour.aspx?ID=2&brandName=NK&addCode=HN 
响应 AIR JORDAN 1 Satin Black Toe‘102019081702^海绵宝宝x Kyrie 5‘112019081601

 ]]
-- 拿到登录的cookie
local function login_mes_cookie(username,password)
    local httpc = http.new()
    


    local resp,err = httpc:request_uri("http://",{
        method = "POST",
        path = "/",
        body = '',   -- 传参
        headers = {
            ["Accept-Language"] = "zh-CN,zh;q=0.9",
            ["Cache-Control"] = "no-cache",
            ["Content-Length"] = '',  -- body 传参
            ["Content-Type"] = "application/x-www-form-urlencoded", 
            ["Host"] = host1,
            ["Origin"] = "http://"..host1,
            ["Proxy-Connection"] = "keep-alive",
            ["Referer"] = "http://"..host1.."/mesplus-lhfsk/home/login",
            ["Upgrade-Insecure-Requests"] = "1",
            ["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36",
        }
    })
    return resp.body

end

return _M