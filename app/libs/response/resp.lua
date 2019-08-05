local _M = {}
local i18n = require 'i18n'
local utils = require("app.libs.utils")
local CODE_PARAMS = require('app.config.code_parameters')

local function response (tab)
     -- 当tab中msg不存在 且 data不存在或者data中不存在msg的值时
    if utils.chk_is_null(tab.msg)  then
        local key = CODE_PARAMS[tab.rv]
        tab.msg = i18n(key) or key.. "(no define)"
        return tab
    end

    -- 当data中不存在msg_args时
    if utils.chk_is_null(tab.msg_args) then
        tab.msg = i18n(tab.msg) or tab.msg.."(no define)"
        return tab
    end

    -- 当data中同时存在msg和msg_args时
    tab.msg =i18n(tab.msg,tab.msg_args) or tab.msg.."(no define)"
    return tab
end

function _M:ok(...)
    local params = {...}
    -- 不传参数请求ok()接口
    if #params == 0 then
        return response({rv=1000})
    end

    -- 传msg参数请求ok()接口
    if type(params[1])=='string' and #params==1 then
        return response({rv=1000,msg=params[1]})
    end

    -- 传入参数为table
    if type(params[1])=='table' then
        params[1]["rv"]=1000
        return response(params[1])
    end

    return nil
end

function _M:err(...)
    local params ={...}
    -- 不传参数请求err()函数
    if #params == 0 then
        return response({rv=1005})
    end
    -- 传入一个rv
    if type(params[1])=='number' and #params == 1 then
        return response({rv=params[1]})
    end
    -- 传入一个msg
    if type(params[1])=='string' and #params == 1 then
        return response({rv=1005,msg=params[1]})
    end
    -- 传入一个表
    if type(params[1])=='table' then
        if utils.chk_is_null(params[1]['rv']) then
            params[1]['rv']=1005
        end
        return response(params[1])
    end
    -- 传入rv和msg两个参数
    if type(params[1])=='number' and type(params[2])=='string' then
        return response({rv=params[1],msg=params[2]})
    end
end

return _M





