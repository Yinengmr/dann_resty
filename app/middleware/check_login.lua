local start_mode = ngx.shared.config:get("config")
local config = require("app.config.".. start_mode)
local cjson = require("cjson")
local jwt = require "resty.jwt"
local pwd_secret = config.pwd_secret
local token_model = require("app.model.token")


local function check_in_white_list(requestPath, whitelist)

	--檢查請求地址是否在白名單中
    local in_white_list = false

    if requestPath == "/" then
    	in_white_list = true
    else
	    for i, v in ipairs(whitelist) do
	    	local match, err = ngx.re.find(requestPath, v)
	        if match then
	            in_white_list = true
	            break
	        end
	    end
	end

	return in_white_list
end

-- 验证登录
local function check_login(whitelist)

	return function(req, res, next)
		--檢查請求地址是否在白名單中
		local requestPath = req.path

	    local in_white_list = check_in_white_list(requestPath, whitelist)


		--在白名單內，直接訪問
		if in_white_list then
			next()
		else
			local auth_header = ngx.var.http_Authorization

			if auth_header == nil then
				-- ngx.log(ngx.WARN, "No Authorization header")
				-- ngx.exit(ngx.HTTP_UNAUTHORIZED)
				return res:json{
					rv = 401,
					msg = "没有jwt"
				}
			end
	
			ngx.log(ngx.INFO, "Authorization: " .. auth_header)
	
			-- require Bearer token
			local _, _, token = string.find(auth_header, "Bearer%s+(.+)")
	
			if token == nil then
				-- ngx.log(ngx.WARN, "Missing token")
				-- ngx.exit(ngx.HTTP_UNAUTHORIZED)
				return res:json{
					rv = 401,
					msg = "没有 token"
				}
			end
	
			ngx.log(ngx.INFO, "Token: " .. token)

			

			local jwt_obj = jwt:verify(pwd_secret, token)
			if jwt_obj.verified == false then
				-- ngx.log(ngx.WARN, "Invalid token: ".. jwt_obj.reason)
				
				-- ngx.status = ngx.HTTP_UNAUTHORIZED
				-- ngx.header.content_type = "application/json; charset=utf-8"
				-- ngx.say(cjson.encode(jwt_obj))
				-- ngx.exit(ngx.HTTP_UNAUTHORIZED)
				
				return res:json{
					rv = 401,
					jwt_obj = jwt_obj,
					msg = "不是有效的token"
				}
			else
				-- token初步验证通过
				local result, error = token_model:verifyToken({
					token = auth_header
				})
				if #result == 0 and not error then
					return res:json{
						rv = 401,
						msg = "token 失效",
					}
				end
				-- 同一时间一个用户只允许一个token有效 不允许多设备同时登录
				-- return res:json{
				-- 	rv = 200,
				-- 	-- msg = cjson.encode(jwt_obj)
				-- 	msg = jwt_obj,
				-- 	a = jwt_obj.payload.exp
				-- }
			end
			req.jwt_obj = jwt_obj.payload
			next()
			
		end
		-- 打印jwt内容
		-- ngx.log(ngx.INFO, "JWT: " .. cjson.encode(jwt_obj))
	end
end
return check_login
