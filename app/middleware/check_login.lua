local cjson = require("cjson")
local jwt = require "resty.jwt"

local secret = "lua-resty-jwt"
-- 验证登录
local function check_login(whitelist)
	
	return function(req, res, next)
		local auth_header = ngx.var.http_Authorization

		if auth_header == nil then
			ngx.log(ngx.WARN, "No Authorization header")
			ngx.exit(ngx.HTTP_UNAUTHORIZED)
		end

		ngx.log(ngx.INFO, "Authorization: " .. auth_header)

		-- require Bearer token
		local _, _, token = string.find(auth_header, "Bearer%s+(.+)")

		if token == nil then
			ngx.log(ngx.WARN, "Missing token")
			ngx.exit(ngx.HTTP_UNAUTHORIZED)
		end

		ngx.log(ngx.INFO, "Token: " .. token)

		local jwt_obj = jwt:verify(secret, token)
		if jwt_obj.verified == false then
			ngx.log(ngx.WARN, "Invalid token: ".. jwt_obj.reason)
			
			ngx.status = ngx.HTTP_UNAUTHORIZED
			ngx.header.content_type = "application/json; charset=utf-8"
			ngx.say(cjson.encode(jwt_obj))
			ngx.exit(ngx.HTTP_UNAUTHORIZED)
		end
		-- 打印jwt内容
		ngx.log(ngx.INFO, "JWT: " .. cjson.encode(jwt_obj))

		next()
	end
end

return check_login
