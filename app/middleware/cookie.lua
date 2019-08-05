local ck = require ("resty.cookie")
local cookie_middleware = function()

    return function(req, res, next)
        local cookie, err = ck:new()
        if not cookie then
            ngx.log(ngx.ERR, err)
            return
        end

        req.cookie = {

            set = function(key, value)
               cookie:set({
                    key = key, value = value, path = "/"
                })
            end,
            
            get = function(key)
                local field, err = cookie:get(key)
              return field
            end
        }
        next()
    end
end

return cookie_middleware
