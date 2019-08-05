--[[
web socket 在連接後需要做的事：
1. 保持連接
2. 解析客戶端傳出的指令，並執行
   { act= [ sub | pub | usub ]
     channel = [ kp:cfg:c:{card_no} | kp:vis:f:{family_code} | kp:vis:lv:{level_code} | kp:vis:ln:{line_code} ]
     }
3. 心跳檢查
5. 訂閱一個指定的頻道
4. 將客戶端訂閱的數據回覆給客戶端

--]]
local cjson     = require("cjson")
local redis     = require("resty.redis")
local server    = require("resty.websocket.server")
local semaphore = require("ngx.semaphore")

local common = require("app.tcp.common")
local config = require("app.config.".. ngx.shared.config:get("config"))
local utils  = require("app.libs.utils")

local ctrl_cmd = require("app.vsws.ctrl_cmd")

local load_eval_scripts  = require("app.vsws.load_eval_scripts")

local pairs = pairs
local ngx_log = common.ngx_log
local encode = cjson.encode
local decode = cjson.decode

local red_conf  = config.redis
local host      = red_conf.connect_config.host
local port      = red_conf.connect_config.port
local timeout   = red_conf.timeout

local pool_size        = red_conf.pool_config.pool_size
local max_idle_timeout = red_conf.pool_config.max_idle_timeout

local ws_conf = config.websocket

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 20)

_M.new_tab = new_tab
_M._VERSION = "0.01"


function _M:new()

    local instance = {}

    instance.closed    = false
    instance.websocket = nil

    instance.redis     = nil
    instance.sema      = nil

    instance.listen_thread = nil
    setmetatable(instance, { __index = self})

    return instance
end

-- 停止WebSocket連接 
function _M:stop()

    self.closed = true

    local ws = self.websocket
    if ws then
        
        self:disconnect_redis()

        local bs = ws:send_close() --發送關閉事件
        if not bs then
          ngx.exit(ngx.HTTP_CLOSE)
        end

        if self.listen_thread then
          ngx.thread.kill(self.listen_thread) --待訂閱線程結束,直接殺了
        end
    end
end

function _M:send(data)
    --ngx_log(ngx.ERR, encode(data))
    local bs, err = self.websocket:send_text(encode(data))
    if not bs then
        ngx_log(ngx.ERR, "failed to send text: ", err)
        self:stop()
    end
end

function _M:connect_redis(is_public_connect)
    
    local red, err = nil, nil;

    if is_public_connect and self.redis then 
        red = self.redis
        return red , err
    end

    red , err = redis:new{ws_conf}
    if not red or err then
        ngx_log(ngx.ERR, "failed to new redis: ", err)
        return ngx.exit(444)
    end

    red:set_timeout(timeout)

    local result, err = red:connect(host, port)
    if not result or err then
        ngx_log(ngx.ERR, "failed to connect to redis: ", err)
        return ngx.exit(444)
    end

    if is_public_connect then
        self.redis = red     
    end    

    return red, err
end

function _M:disconnect_redis()

    local red = self.redis 

    if red then --沒起作用
        local result, err = red:unsubscribe()
        red:close() --關閉訂閱redis連接
        self.redis = nil
    end
end

function _M:subscribe(channel_name)

    local red, err = self:connect_redis(true)

    self.semaphore:wait(1)
    local res, err = red:subscribe(channel_name)

    if not self.listen_thread then 
        self.listen_thread, err = ngx.thread.spawn(self.listen, self)
    end

    self.semaphore:post(1)

    if not res then
        return { rv = 500, 
                msg = err, 
                act = "subscribe",
                 ch = channel_name, 
                 at = ngx.time() }
    else
        return {  rv = 200, 
                 msg = "success",
                 act = res[1],
                  ch = res[2],
              ch_num = res[3],
                  at = ngx.time() }
    end
end

function _M:unsubscribe(channel_name)

    local red, err = self:connect_redis(true)

    self.semaphore:wait(1)
    local res, err
    if channel_name then
       res, err = red:unsubscribe(channel_name)
    else
       res, err = red:unsubscribe()
    end
    
    self.semaphore:post(1)

    if not res then
        return { rv = 500, 
                msg = err, 
                act = "unsubscribe",
                 ch = channel_name, 
                 at = ngx.time() }
    else
        return {  rv = 200, 
                 msg = "success",
                 act = res[1],
                  ch = res[2],
              ch_num = res[3],
                  at = ngx.time() }
    end
end

function _M:publish(channel_name,data)
    
    local red, err = self:connect_redis(false)

    self.semaphore:wait(1)
    local res, err = red:publish(channel_name,encode(data))
    local ok, err = red:set_keepalive(max_idle_timeout, pool_size)
    
    if not ok or err then
	    ngx_log(ngx.ERR,"failed to set_keepalive: ", err)
	    return
    end
    
    self.semaphore:post(1)

    if not res then
        return { rv = 500, 
                msg = err, 
                act = "publish",
                 ch = channel_name, 
                 at = ngx.time() }
    else
        return {  rv = 200, 
                 msg = "success",
                 act = "publish",
                  ch = channel_name,
              ch_num = res,
                  at = ngx.time() }
    end
end

function _M:ping()
    return {  rv = 200, 
             msg = "success",
             act = "pong",
              at = ngx.time()}
end

function _M:mount(...)
    local params = {...}
    if #params == 3 then 
        local cmd_name = params[1]
        local path = params[2]
        local fun_name = params[3]
        local cmd_file = require(path)

        self[cmd_name] = cmd_file[fun_name]
    end

    if #params == 1 then 
        local path = params[1]
        local cmd_file = require(path)
        local cmd_fun_mapping = cmd_file.mapping

        for k,v in pairs(cmd_fun_mapping) do
            self[k] = cmd_file[v]
        end
    end
end

function _M:execute(cmd_text)

    local ok, cmd = pcall(function() return decode(cmd_text) end)
    
    --解析消息失敗
    if not ok then
        ngx_log(ngx.ERR, "failed to decode reply data: ", cmd)
        self:send({ rv = 502, 
                    msg = "failed to decode reply data: " .. cmd ,
                    at = ngx.time() })
        return
    end

    if not cmd.act then
        self:send({ rv = 500, msg = "cmd error"})
    elseif cmd.act == "sub" then
        self:send(self:subscribe(cmd.ch))
    elseif cmd.act == "pub" then
        self:send(self:publish(cmd.ch, cmd.dat))
    elseif cmd.act == "usub" then
        self:send(self:unsubscribe(cmd.ch))
    elseif cmd.act == "ping" then
        self:send(self:ping())
    else
        self:send(self[cmd.act](self,cmd))
    end
end    
-- 讀出需要訂閱的頻道 訂閱，讀取回覆
function _M:listen()
    while not self.closed do
        
        local red, err = self:connect_redis(true)

        self.semaphore:wait(1)
        local ret, err = red:read_reply()
        
        if not ret and err == "not subscribed" then
            ngx_log(ngx.ERR, "failed to read reply: ", err)
            self:send({ rv = 501, 
                       msg = "failed to read reply: " .. err })
            self.listen_thread = nil 
            break
        end
        
        --報錯，沒有數據，也沒有超時
        if not ret and err ~= "timeout" then
            ngx_log(ngx.ERR, "failed to read reply: ", err)

            self:send({ rv = 501, 
                       msg = "failed to read reply: " .. err })
        end
        
        --有數據,數據類型爲: message
        if ret and ret[1] == "message" then

            local ok, data = pcall(function() return decode(ret[3]) end)
            --解析消息失敗
            if not ok then
                ngx_log(ngx.ERR, "failed to decode reply data: ", data)
                self:send({ rv = 502, 
                           msg = "failed to decode reply data: " .. data ,
                            at = ngx.time() })
            else
            --生成回傳的json數據
            self:send({     rv = 200, 
                           msg = "success",
                           dat = data,
                           act = ret[1], 
                            ch = ret[2],
                            at = ngx.time() })
            end
        end
    
        self.semaphore:post(1)

        ngx.sleep(0.05)

    end
end

--啓動WebSocket連接
function _M:start()

    local sema, err = semaphore.new(1)
    if not sema or err then
        ngx_log(ngx.ERR, "failed to new semaphore: ", err)
        return ngx.exit(444)
    end
    
    self.semaphore = sema

    ngx_log(ngx.DEBUG, "semaphore cnt: ",sema:count())

    local wb, err = server:new{ ws_conf }
    
    if not wb then
        ngx_log(ngx.ERR, "failed to new websocket: ", err)
        return ngx.exit(444)
    end

    self.websocket = wb
    while true do
        
        local data, typ, err = wb:recv_frame()
        --當連接被損壞了
        if wb.fatal then
            ngx_log(ngx.ERR, "failed to receive frame: ", err)
            return ngx.exit(444)
        end

        --沒有數據的情況下，發送心跳檢查:ping
        if not data then            
            local bytes, err = wb:send_ping()
            if not bytes then
                ngx_log(ngx.ERR, "failed to send ping: ", err)
                self.closed = true;
                --sema:post(1);
                break
            end
        --客戶端主動請求斷開
        elseif typ == "close" then
            self.closed = true;
            ngx_log(ngx.DEBUG,"closing WS")
            --sema:post(1);
            break
        --客戶端心跳檢查
        elseif typ == "ping" then
            local bytes, err = wb:send_pong()
            if not bytes then
                ngx_log(ngx.ERR, "failed to send pong: ", err)
                self.closed = true;
                --sema:post(1);
                break
            end
        --客戶端回覆服務端的心跳檢查
        elseif typ == "pong" then
            ngx_log(ngx.INFO, "client ponged")
        --客戶端發送的文本數據
        elseif typ == "text" then
            self:execute(data)
            
        elseif typ == "continuation" then
            -- ignore
        elseif typ == "binary" then
            -- ignore
        end
    end
    
    ngx_log(ngx.INFO, "closing")
    wb:send_close()
    self:stop()

end

return _M
