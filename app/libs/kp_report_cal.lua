
local cjson = require("cjson")
local utils = require("app.libs.utils")
local report_model = require('app.model.key-position.report')


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 5)

_M.new_tab = new_tab
_M._VERSION = "0.01"

local function clone( object )
    local lookup_table = {}
    local function copyObj( object )
        if type( object ) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs( object ) do
            new_table[copyObj( key )] = copyObj( value )
        end
        return setmetatable( new_table, getmetatable( object ) )
    end
    return copyObj( object )
end

local function chg_target(target,source,action_type)
    target['action_type'] = action_type
end

local function is_target(target,source)
    if target['action_type'] == 2 then
        if source['action_type'] == target['action_type'] then
            if utils.chk_is_null(source['emp_no']) then
                return false
            end
            return true
        end
    else
        if target['insert_data']['uid'] == source['uid'] and 
           target['action_type'] == source['action_type'] and 
           target['insert_data']['pcid'] == source['pcid'] and 
           target['insert_data']['allow'] == source['allow'] and 
           target['insert_data']['emp_no'] == source['emp_no']
        then
            return true
        else
            return false
        end
    end
end

local function build_sqldata(sourcedata)
    local sqldata = {}
    for _,v in pairs(sourcedata) do
        table.insert( sqldata,v['insert_data']['family_code'])
        table.insert( sqldata,v['insert_data']['level_code'])
        table.insert( sqldata,v['insert_data']['line_code'])
        table.insert( sqldata,v['insert_data']['kp_name'])
        table.insert( sqldata,v['insert_data']['kp_type'])
        table.insert( sqldata,v['insert_data']['emp_no'])
        table.insert( sqldata,v['insert_data']['emp_name'])
        table.insert( sqldata,v['insert_data']['action_at'])
        table.insert( sqldata,v['remove_data']['action_at'])
        table.insert( sqldata,v['insert_data']['allow'])
        table.insert( sqldata,v['insert_data']['uid'])
        table.insert( sqldata,v['insert_data']['post_cert_code'])
    end
    return sqldata
end

function _M.caculate_report()
    local ONLINE = 0
    local OFFLINE = 1
    local INSERT_CARD = 2
    local REMOVE_CARD = 3

    local target = {
        ['action_type'] = INSERT_CARD,
        ['insert_data'] = '',
        ['remove_data'] = ''
    }

    local caculate_data = {}
    local caculate_id = {}

    local act_his, err = report_model:devices_act_his()
    if not act_his or err then
        ngx.log(ngx.ERR,'查询历史记录错误')
        return
    end
    if #act_his > 0 then
        for _,v in pairs(act_his) do
            if is_target(target,v) then
          --      ngx.log(ngx.ERR,'处理数据:' .. cjson.encode(v))
    
                if target['action_type'] == INSERT_CARD then
                    target['insert_data'] = v
                    chg_target(target,v,REMOVE_CARD)
                else
                    if target['action_type'] == REMOVE_CARD then
                        target['remove_data'] = v
                        table.insert( caculate_data, clone(target))
                        table.insert( caculate_id,target['insert_data']['id'])
                        table.insert( caculate_id,target['remove_data']['id'])
                        chg_target(target,v,INSERT_CARD)
                    end
                end   
            else
                chg_target(target,v,INSERT_CARD)
            end
        end
        local sqldata = build_sqldata(caculate_data)
    
        local result, err = report_model:insert_report_mutl(
                            #caculate_data,sqldata)
        if not result or err then
            ngx.log(ngx.ERR,'插入报表失败')
            return
        end
        local result, err = report_model:update_device_act_cal(caculate_id)
        if not result or err then
            ngx.log(ngx.ERR,'更新失败')
            return
        end
    end

    local ok, err = ngx.timer.at(60*60*1, caculate_report)
	if not ok then
	  ngx_log(ngx.ERR, "failed to create the timer: ", err)
	  return
	end
end

return _M