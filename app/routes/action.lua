local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")


-- local config  = require("app.config.".. ngx.shared.config:get("config"))
local config  = require("app.config.config-local")
local action_model = require("app.model.action")
local lor = require("lor.index")
local _M = lor:Router()

local MAX_NUM_USER = 22

local emp = {
    {
        no = 'F2846970',
        name = '程义能',
        status = 0
    },
    {
        no = 'F2845879',
        name = '杨康',
        status = 0
    },
    {
        no = 'F2847550',
        name = '邹东平',
        status = 0
    },
    {
        no = 'F2847582',
        name = '杨光明',
        status = 0
    },
    {
        no = 'F2846776',
        name = '胡鵬',
        status = 0
    },
    {
        no = 'F2846786',
        name = '廖喜',
        status = 0
    },
    {
        no = 'F2847568',
        name = '陳思思',
        status = 0
    },
    {
        no = 'F2846176',
        name = '麻安龍',
        status = 0
    },
    {
        no = 'F2846751',
        name = '任桃紅',
        status = 0
    },
    {
        no = 'F2847765',
        name = '王歡',
        status = 0
    },
    {
        no = 'F2847464',
        name = '王芳',
        status = 0
    },
    {
        no = 'F2847577',
        name = '李名揚',
        status = 0
    },
    {
        no = 'F2847583',
        name = '徐穎',
        status = 0
    },
    {
        no = 'F2847588',
        name = '郭子佩',
        status = 0
    },
    {
        no = 'F2816897',
        name = '沈軍兵',
        status = 0
    },
    {
        no = 'F2847964',
        name = '徐海帆',
        status = 0
    },
    {
        no = 'F2848022',
        name = '韋新會',
        status = 0
    },
    {
        no = 'F2848035',
        name = '譙豐',
        status = 0
    },
    {
        no = 'F2848001',
        name = '劉偉強',
        status = 0
    },
    {
        no = 'F2847965',
        name = '王楚',
        status = 0
    },
    {
        no = 'F2847233',
        name = '黄康高',
        status = 0
    },
    {
        no = 'F2845367',
        name = '杨帆',
        status = 0
    },
    {
        no = 'Ann',
        name = '宋沫盈',
        status = 0
    },
    {
        no = 'j',
        name = 'J.malminds',
        status = 0
    },
    {
        no = 'Maxine Lee',
        name = 'Maxine',
        status = 0
    },
}


-- 抽签页面
_M:get("", function(req, res, next)
     res:render('action/action')
end)

-- 获取参与抽签人员
_M:get('/emp',function(req, res, next)
    local new_arr = {}
    local emp_all = req.session.get("all_user") or emp

    while(#emp_all>0)
    do
        local no = math.random(1,#emp_all)
        
        --[[ if #new_arr ==7 then
            table.insert(new_arr,{
                no = false,
                name = '站位',
                order_item = #new_arr+1
            })
        end ]]
        if emp_all[no].no ~=false then
            emp_all[no].order_item = #new_arr+1
            table.insert(new_arr,emp_all[no])
            table.remove(emp_all,no)
        end
        
    end
    req.session.set("all_user",new_arr)
    return res:json{
        data = new_arr,
        rv = 200
    }
end)

-- 获取号码
local function get_lucky(data,pass)
    local no = math.random(1,MAX_NUM_USER)

    if #pass == 0 then
        return no
    end
    ngx.log(ngx.DEBUG,'======抽中====='..data[no].name)
    local is_pass = false
    for k=1,#pass  do
        if data[no].no== pass[k].emp_no then
            ngx.log(ngx.DEBUG,'抽中了白名单',data[no].no)
            is_pass = true
            break
        end
    end
    if is_pass then
        ngx.log(ngx.DEBUG,'抽中了白名单再次抽奖'..data[no].no)
        return get_lucky(data,pass)
    end
    return no
end

-- 抽签接口
_M:post('',function(req,res,next)
    local type = req.query.type
    local data = req.session.get("all_user") or {}
    if #data < 1 then
        return res:json{
            rv = 501,
            data = #data,
            msg = 'session 已过期，请刷新页面！'
        }
    end
    local pass = {}

    if not utils.chk_is_null(type) and tonumber(type) ==1 then

        -- 略过最近的4人
        local resp,err = action_model:his_chouqian(1,true)
        pass = resp or {}

        table.insert(pass,{
            emp_name = '程义能',
            emp_no='F2846970'
        })
        table.insert(pass,{
            emp_name = 'Maxine',
            emp_no='Maxine Lee'
        })
        table.insert(pass,{
            emp_name = 'J.malminds',
            emp_no='j'
        })
    end
    if not utils.chk_is_null(type) and tonumber(type) ==2 then 
        local data = req.session.get("all_user") or {}
        local resp,err = action_model:his_chouqian(2,false)
        pass = resp or {}

        for k=1,#data do
            if k == no then
                data[k].status = 1
                ngx.log(ngx.DEBUG,'===============',data[no].status)
                -- table.insert(pass,data[no])
            end
        end
        req.session.set("all_user",data)
    end
    
    local no = get_lucky(data,pass)

    local lucky_his = req.session.get("lucky_his") or {}

    -- table.insert(lucky_his,{
    --     name = data[no].name,
    --     no   = data[no].order_item,
    --     emp_no  = data[no].no,
    --     time = #lucky_his+1
    -- })
    -- req.session.set("lucky_his",lucky_his)
    -- 写入抽签历史
    -- ngx.timer.at(2,action_model:insert_chouqian_his(data[no].name,data[no].no,type))
    if not utils.chk_is_null(type) and tonumber(type) ~=0 then
        local resp,err = action_model:insert_chouqian_his(data[no].name,data[no].no,type)
    end
    return res:json{
        rv = 200,
        lucky = {
            name = data[no].name,
            no   = data[no].order_item,
            emp_no  = data[no].no,
            -- lucky_his = lucky_his,
            type = type
        }
    }
end)

_M:get('/his',function(req,res,next)
    local type = req.query.type or ''
    local resp,err = action_model:his_chouqian(type,false)
    if not err and resp then
        return res:json{
            rv = 200,
            count = #resp,
            data = resp
        }
    end
end)

_M:get('/emp_',function(req,res,next)
    local new_arr = req.session.get("all_user") or {}
    return res:json{
        data = new_arr,
        rv = 200
    }
end)
return _M