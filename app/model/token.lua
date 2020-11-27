local DB = require("app.libs.db")
local db = DB:new()

local _M = {}

-- 写入token
function _M:writeToken(sqlparams)
    local sql = [[
        INSERT INTO hw_user_token 
        (`user_id`, `token`)
        VALUES (:user_id, :token)
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

-- token作废
function _M:cancelToken(sqlparams)
    local sql = [[
        UPDATE hw_user_token
        SET 
            `status`= 0
        WHERE status = 1 AND `user_id` = :user_id
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

-- 查询token 有效性
function _M:verifyToken(sqlparams)
    local sql = [[
        SELECT *
        FROM hw_user_token
        WHERE status = 1 AND `token` = :token
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

function _M:findUserToken(sqlparams)
    local sql = [[
        SELECT *
        FROM hw_user_token
        WHERE status = 1 AND `user_id` = :user_id
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end
return _M