local DB = require("app.libs.db")
local db = DB:new()

local users = {}

-- 查询用户名
function users:findUserName(sqlparams)
    local sql = [[
        SELECT `id`, `username`, `email`, `phone`
        FROM hw_user
        WHERE `username`= :username
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end
-- 查询邮箱
function users:findEmail(sqlparams)
    local sql = [[
        SELECT `id`, `username`, `email`, `phone`
        FROM hw_user
        WHERE `email`= :email
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

-- 查询电话
function users:findPhone(sqlparams)
    local sql = [[
        SELECT `id`, `username`, `email`, `phone`
        FROM hw_user
        WHERE `phone`= :phone
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

-- 创建用户
function users:add(sqlparams)
    local sql = [[
        INSERT INTO hw_user 
        (`username`, `password`)
        VALUES (:username, :password)
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end

-- 修改用户名字
function users:updateName(sqlparams)
    local sql = [[
        UPDATE hw_user 
        SET 
            `username`=:username
        WHERE id= :id
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end
-- 修改用户信息
function users:updateBase(sqlparams)
    local sql = [[
        UPDATE hw_user 
        SET 
            `phone`=:phone, `email`=:email
        WHERE id= :id
    ]]
	local res,err = db:query(sql, sqlparams)
    return res,err
end
-- 查询所有用户
function users:getAll()
    local sql = [[
        SELECT 
        `id`,
        `username`,
        `is_delete`,
        `email`,
        `phone`,
        `inline_time`,
        `last_login_at`,
        `last_login_ip`,
        `creat_at`,
        `update_at`
        FROM hw_user
    ]]
	local res,err = db:query(sql)
    return res,err
end

return users