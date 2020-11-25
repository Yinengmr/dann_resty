local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")

local users_model = require("app.model.users")


local start_mode = ngx.shared.config:get("config") 
local config = require("app.config.".. start_mode)

local pwd_secret = config.pwd_secret

local lor = require("lor.index")
local _M = lor:Router()

_M:post("/create", function(req, res, next)
    local username = utils.trim(req.body.username) 
    local password = utils.trim(req.body.password)

    if utils.chk_is_null(username, password) then
        return res:json{
            rv = 501,
            msg = "參數錯誤"
        }
    end

    local result, error = users_model:findUserName({
        username = username
    })
    if #result > 0 then
        return res:json{
            rv = 501,
            msg = '用户名已被使用'
        }
    end
    password = utils.encode(password .. "#" .. pwd_secret)
    users_model:add({
        username = username,
        password = password
    })
    return res:json{
        rv = 200,
        data = {
            username = username,
            password = password
        },
        msg = 'success'
    }

end)

-- 用户列表
_M:get("", function(req, res, next)
    local result,error = users_model:getAll()
    return res:json{
        rv = 200,
        data = result,
        msg = 'success'
    }
end)



return _M