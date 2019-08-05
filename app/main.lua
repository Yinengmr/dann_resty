
local cjson = require("cjson")
local config = require("app.config.".. ngx.shared.config:get("config"))

local allow_cross_domain = config.allow_cross_domain

-- 如果跨域
if allow_cross_domain then
  local http_method = ngx.req.get_method()
  if http_method=="OPTIONS" then
      ngx.status = 200
      local json = cjson.encode({  rv = 200,
                                  msg = "success"
                                })
      local header_origin =  ngx.header["origin"]
      ngx.header['Access-Control-Allow-Origin'] = header_origin or 'null'  --'*'
      ngx.header['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
      ngx.header['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept'
      ngx.header['Access-Control-Allow-Credentials'] = 'true'
      ngx.say(json)
      --ngx.exit()
      return
  end
end

local app = require("app.server")
app:run()
