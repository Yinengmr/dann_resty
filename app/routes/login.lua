local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")

local login_model = require("app.model.login")


local start_mode = ngx.shared.config:get("config")
local config = require("app.config.".. start_mode)

local pwd_secret = config.pwd_secret

local lor = require("lor.index")
local _M = lor:Router()

_M:post("", function(req, res, next)

    local loginType = req.body.loginType

    local loginName = {
        username = utils.trim(req.body.username),
        email = utils.trim(req.body.email),
        phone = utils.trim(req.body.phone)
    }

    local password = utils.trim(req.body.password)
    if utils.chk_is_null(loginName[loginType], password) then
        return res:json{
            rv = 501,
            msg = "參數錯誤"
        }
    end

    password = utils.encode(password .. "#" .. pwd_secret)
    local result, error = login_model:login({
        loginType = loginType,
        loginName = loginName[loginType],
        password = password
    })

    if not error and #result > 0 then
        return res:json{
            rv = 200,
            data = result[1],
            token = "",
            msg = "success"
        }
    end

    return res:json{
        rv = 500,
        data = {
            loginType = loginType,
            loginName = loginName[loginType],
            password = password
        },
        result = result,
        msg = "登录名或者密码有误"
    }
end)

return _M