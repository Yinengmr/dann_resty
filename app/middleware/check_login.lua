-- 验证登录
local function check_login(whitelist)
	
	return function(req, res, next)
		next()
	end
end

return check_login
