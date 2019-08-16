local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")


local config = ngx.shared.config:get("config") 

local lor = require("lor.index")
local _M = lor:Router()

local MAX_NUM_USER = 22

local emp = {
    {
        no = 'F2846970',
        name = '程义能',
    },
    {
        no = 'F2845879',
        name = '杨康',
    },
    {
        no = 'F2847550',
        name = '邹东平',
    },
    {
        no = 'F2847582',
        name = '杨光明',
    },
    {
        no = 'F2846776',

        name = '胡鵬',
    },
    {
        no = 'F2846786',
        name = '廖喜',
    },
    {
        no = 'F2847568',
        name = '陳思思',
    },
    {
        no = 'F2846176',
        name = '麻安龍',
    },
    {
        no = 'F2846751',
        name = '任桃紅',
    },
    {
        no = 'F2847765',
        name = '王歡',
    },
    {
        no = 'F2847464',
        name = '王芳',
    },
    {
        no = 'F2847577',
        name = '李名揚',
    },
    {
        no = 'F2847583',
        name = '徐穎',
    },
    {
        no = 'F2847588',
        name = '郭子佩',
    },
    {
        no = 'F2816897',
        name = '沈軍兵',
    },
    {
        no = 'F2847964',
        name = '徐海帆',
    },
    {
        no = 'F2848022',
        name = '韋新會',
    },
    {
        no = 'F2848035',
        name = '譙豐',
    },
    {
        no = 'F2848001',
        name = '劉偉強',
    },
    {
        no = 'F2847965',
        name = '王楚',
    },
    {
        no = 'F2847233',
        name = '黄康高',
    },
    {
        no = 'F2845367',
        name = '杨帆',
    },
    {
        no = 'lxm',
        name = '刘雪梅',
    },
    {
        no = 'j',
        name = 'J.malminds',
    },
    {
        no = 'Maxine Lee',
        name = 'Maxine',
    },
}

-- 产生随机数
local function range()
    local no = math.random(1,MAX_NUM_USER)
    return no
end

-- 抽签页面
_M:get("", function(req, res, next)
     res:render('action/action')
end)

-- 获取参与抽签人员
_M:get('/emp',function(req, res, next)
    local new_arr = {}
    while(#emp>0)
    do
        local no = math.random(1,#emp)
        
        --[[ if #new_arr ==7 then
            table.insert(new_arr,{
                no = false,
                name = '站位',
                order_item = #new_arr+1
            })
        end ]]
        if emp[no].no ~=false then
            emp[no].order_item = #new_arr+1
            table.insert(new_arr,emp[no])
            table.remove(emp,no)
        end
        
    end
    req.session.set("all_user",new_arr)
    return res:json{
        data = new_arr,
        rv = 200
    }
end)

-- 获取号码
local function get_lucky(data)
    local no = range()
    -- for i=1,#config.no_lucky do
    --     if data[no].no == config.no_lucky[i] then
    --         get_lucky()
    --     end
    -- end
    if data[no].no=='F2846970' 
    or data[no].no=='F2845879' 
    or data[no].no=='F2847582' 
    or data[no].no=='F2847550' 
    or not data[no].no then
        get_lucky()
    end
    return no
end

-- 抽签接口
_M:post('',function(req,res,next)
    local data = req.session.get("all_user")
    local no = get_lucky(data)

    local lucky_his = req.session.get("lucky_his") or {}
    table.insert(lucky_his,{
        name = data[no].name,
        no   = data[no].order_item,
        emp_no  = data[no].no,
        time = #lucky_his+1
    })
    req.session.set("lucky_his",lucky_his)
    
    return res:json{
        rv = 200,
        lucky = {
            name = data[no].name,
            no   = data[no].order_item,
            emp_no  = data[no].no,
            lucky_his = lucky_his
        }
    }
end)
return _M