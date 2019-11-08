local DB = require("app.libs.db")
local db = DB:new()

local action = {}

-- 记录抽签历史
function action:insert_chouqian_his(emp_name,emp_no,type)
    local sql = [[
        INSERT INTO danny_chouqian_his (emp_name,emp_no, type)
        VALUES (:emp_name, :emp_no, :type)
    ]]
    local sqlparams = {
        emp_name = emp_name,
        emp_no = emp_no,
        type = type
    }
	local res,err = db:query(sql,sqlparams)
    return res,err
end

-- 查询抽签历史
-- limit true or false
function action:his_chouqian(type,limit)
    local sql = [[
        SELECT *
        FROM danny_chouqian_his
        where type = :type
        order by id desc
    ]]
    if limit then
        sql = sql..[[ LIMIT 4 ]]
    end
    local sqlparams = {
        type = type
    }
	local res,err = db:query(sql,sqlparams)
    return res,err

end

return action