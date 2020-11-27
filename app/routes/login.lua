local pairs = pairs
local ipairs = ipairs
local cjson = require("cjson")
local utils = require("app.libs.utils")

local login_model = require("app.model.login")
local token_model = require("app.model.token")

local jwt = require "resty.jwt"

-- local ngx_re = require "ngx.re"
-- ngx_re.split('asasas asasa', ' '),

local start_mode = ngx.shared.config:get("config")
local config = require("app.config.".. start_mode)

local pwd_secret = config.pwd_secret

local lor = require("lor.index")
local _M = lor:Router()


-- 生成token
local function makeToken(username, userid)
    local jwt_token = 'Bearer '..jwt:sign(
        pwd_secret,
        {
            header={
                typ="JWT",
                alg="HS256",
            },
            payload={
                --[[ 
                    iss (issuer)：签发人
                    exp (expiration time)：过期时间
                    sub (subject)：主题
                    aud (audience)：受众
                    nbf (Not Before)：生效时间
                    iat (Issued At)：签发时间
                    jti (JWT ID)：编号
                ]]
                iat = ngx.time(),
                exp = ngx.time() + 60*60*2,
                userInfo = {
                    username = username,
                    userid   = userid
                }
            }
        }
    )
    return jwt_token
end
_M:post("", function(req, res, next)
    local jwt_token = nil
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
    -- 密码通过
    if not error and #result > 0 then
        -- 查询token
        local result1, error1 = token_model:findUserToken({
            user_id = result[1].id
        })
        if not error1 and #result1 > 0 then
            local _, _, token = string.find(result1[1].token, "Bearer%s+(.+)")

            local jwt_obj = jwt:verify(pwd_secret, token)
            if jwt_obj.verified == false then
                -- token 过期 生成jwt
                jwt_token = makeToken(result[1].username, result[1].id)
                token_model:cancelToken({
                    user_id = result[1].id,
                })

                token_model:writeToken({
                    user_id = result[1].id,
                    token = jwt_token
                })
            else
                -- 避免重复签发token
                -- 最新签发的token没过期 判断登录时间间隔 间隔超过半小时则作废token 重新生成token
                if (ngx.time() - jwt_obj.payload.iat) > 60*30 then
                    jwt_token = makeToken(result[1].username, result[1].id)
                    token_model:cancelToken({
                        user_id = result[1].id,
                    })

                    token_model:writeToken({
                        user_id = result[1].id,
                        token = jwt_token
                    })
                else
                    jwt_token = result1[1].token
                end
            end
        else
            -- 没有可用token 生成token
            jwt_token = makeToken(result[1].username, result[1].id)
            token_model:writeToken({
                user_id = result[1].id,
                token = jwt_token
            })
        end
        -- 签发token
        return res:json{
            rv = 200,
            data = result[1],
            time = ngx.time() + 60*60*2,
            jwt_token = jwt_token,
            jwt_obj = req.jwt_obj,
            msg = "success"
        }
    end

    return res:json{
        rv = 500,
        msg = "登录名或者密码有误"
    }
end)

return _M