local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")


local jwt = require "resty.jwt"
local secret = "lua-resty-jwt"

local start_mode = ngx.shared.config:get("config") 
local config = require("app.config.".. start_mode)
local menu_config = config.menu

local lor = require("lor.index")
local _M = lor:Router()


_M:get("", function(req, res, next)
     -- return ngx.say('<a><a href="/action">抽签</a></a>')
     res:render('home')
end)

_M:get("/jwt", function(req, res, next)
     -- 生成jwt
     local jwt_token = 'Bearer '..jwt:sign(
          secret,
          {
               header={
                    typ="JWT",
                    alg="HS256"
               },
               payload={
                    --[[ 
                         iss (issuer)：签发人
                         exp (expiration time)：过期时间
                         sub (subject)：主题
                         aud (audience)：受众
                         nbf (Not Before)：生效时间
                         iat (Issued At)：签发时间
                         jti (JWT ID)：编号
                     ]]
                    exp=1606373752,
                    foo="bar",
                    name="danny"
               }
          }
     )
     -- local jwt_obj = jwt:load_jwt(jwt_token)
     -- ngx_log(ngx.ERR, "jwt-err", jwt_obj)
     return ngx.say(jwt_token)
     -- res:render('home')
end)


return _M