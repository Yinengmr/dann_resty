local string_find = string.find
local lor = require("lor.index")
local router = require("app.router")
local middleware = require("app.middleware")
local start_mode = ngx.shared.config:get("config") 
local config = require("app.config.".. start_mode)
local view_config = config.view_config

local app = lor()

-- 模板配置
app:conf("view enable", true)
app:conf("view engine", view_config.engine)
app:conf("view ext", view_config.ext)
app:conf("view layout", "")
app:conf("views", view_config.views)

middleware:load(app)

router:load(app) -- 業務路由處理

-- 錯誤處理插件，可根據需要定義多個
app:erroruse(function(err, req, res, next)
    ngx.log(ngx.ERR, err)

    if req:is_found() ~= true then
        if string_find(req.headers["Accept"], "application/json") then
            res:status(404):json({
                rv = 404,
                msg = "404! sorry, not found."
            })
        else
            res:status(404):send("404! sorry, not found. " .. (req.path or ""))
        end
    else
        if string_find(req.headers["Accept"], "application/json") then
            res:status(500):json({
                rv = 500,
                msg = "500! unknown error."
            })
        else
            res:status(500):send("unknown error")
        end
    end
end)

return app
