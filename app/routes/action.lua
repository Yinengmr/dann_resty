local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")

local emp = require("app.emp_list")

-- local config  = require("app.config.".. ngx.shared.config:get("config"))
local config  = require("app.config.config-local")
local action_model = require("app.model.action")
local lor = require("lor.index")
local _M = lor:Router()

local MAX_NUM_USER = 22

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
            emp_name = '刘雪梅',
            emp_no='G4704621'
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

    local lipin = req.query.lipin or ''
   
    local resp,err = action_model:his_chouqian(2,false)

    for j =1, #new_arr do
        new_arr[j].status = 0
    end

    if not utils.chk_is_null(lipin) and #new_arr > 0 and #resp >0 then
        for k=1,#resp do
            for j =1, #new_arr do
                if resp[k].emp_no == new_arr[j].no then
                    new_arr[j].status = 1
                end
            end
        end
        req.session.set("all_user",new_arr)
    end
        
    return res:json{
        data = new_arr,
        rv = 200
    }
end)

_M:post('/del_his',function(req,res,next)
    local id = req.body.id or nil
    local type = req.body.type or nil

    if utils.chk_is_null(id,type) then
        return res:json{
            rv = 501,
            msg = "參數錯誤"
        }
    end
    if type ~= 2 then
        return res:json{
            rv = 501,
            msg = "參數錯誤"
        }
    end
    local result,err = action_model:del_his(type,id)
    return res:json{
        msg = "success",
        rv = 200
    }
end)
return _M