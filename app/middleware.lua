
local start_mode = ngx.shared.config:get("config") 
local config = require("app.config.".. start_mode)

local whitelist     = config.whitelist
local view_config   = config.view_config
local upload_config = config.upload_config

local _M = {}

function _M:init_config()
    
return {
    session = { 
        midleware = "app.middleware.session", 
           active = true,
           config = {
                timeout = 3600, -- default session timeout is 3600 seconds
                secret = config.session_secret,
                storage = "redis"
            }
    },
    cookie = { 
        midleware = "app.middleware.cookie", 
           active = true,
           config = nil 
    },
    inject_version = { 
        midleware = "app.middleware.inject_app_info", 
           active = true,
           config = nil 
    },
    powered_by = { 
        midleware = "app.middleware.powered_by", 
           active = true,
           config = 'Lor Framework' 
    },
    uploader = {
        midleware = "app.middleware.uploader", 
        active = true,
        config = {
            dir = upload_config.dir
        }
    },
    check_login = {
        midleware = "app.middleware.check_login", 
        active = true,
        config = whitelist   
    },
}
end

function _M:load(app)

    for _ , mw in pairs(self:init_config())do
        if mw.active then
            local _mw = require(mw.midleware)
            app:use(_mw(mw.config))
        end
    end

end

return _M