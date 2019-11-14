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
        SELECT *,
        case type when 1 then '专题演讲' 
            when 2 then '礼品互赠'
        
        else '其他' end as remark
        FROM danny_chouqian_his
    ]]
    if type ~= '' then
        sql = sql..[[ where type = :type ]]
    end
    sql = sql..[[ order by id desc ]]
    if limit then
        sql = sql..[[ LIMIT 4 ]]
    end
    local sqlparams = {
        type = type
    }
	local res,err = db:query(sql,sqlparams)
    return res,err

end

function action:del_his(type,id)
    local sql = [[
        delete from  danny_chouqian_his
        where id = :id
    ]]
    local sqlparams = {
        type = type,
        id = id
    }
    local res,err = db:query(sql,sqlparams)
    return res,err
end
return action