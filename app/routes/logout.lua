local token_model = require("app.model.token")

local lor = require("lor.index")
local _M = lor:Router()

_M:post("", function(req, res, next)
    if req.jwt_obj then
        local result, error = token_model:cancelToken({
            user_id = req.jwt_obj.userInfo.userid
        })
        if not error and result then
            return res:json{
                rv = 200,
                -- result = result,
                -- data = req.jwt_obj,
                msg = "success"
            }
        end
    end

    return res:json{
        rv = 500,
        msg = "未知错误"
    }
end)

return _M