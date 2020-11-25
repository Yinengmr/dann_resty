local DB = require("app.libs.db")
local db = DB:new()

local login = {}

-- 登录
function login:login(sqlparams)
    local sql = [[
        SELECT `id`, `username`, `email`, `phone`
        FROM hw_user
        WHERE `]]..sqlparams['loginType'] ..[[` = :loginName
        and `password`= :password
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

return login