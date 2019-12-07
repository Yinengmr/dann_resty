-- 定时任务管理页

local key = require("app.services.key")
local DELAY_TIME_NUM = 1

local ngx = ngx
local ngx_log = ngx.log


if 0 == ngx.worker.id() then
    -- ngx_log(ngx.DEBUG, "生成抽签口令")
    local ok, err = ngx.timer.at(DELAY_TIME_NUM, key.get_key, key)
end