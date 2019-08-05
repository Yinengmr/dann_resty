local config = require("app.config.".. ngx.shared.config:get("config"))
local http = require("socket.http")
local ltn12 = require("ltn12")
local utils = require("app.libs.utils")
local uuid = require 'resty.jit-uuid'
uuid.seed()
local cjson = require("cjson")
local redis = require("resty.redis")
local random = require "resty.random".bytes
local filedir = config.upload_files.dir

local timeout = config.redis.timeout
local host 		= config.redis.connect_config.host
local port 		= config.redis.connect_config.port
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local pool_size 			 = config.redis.pool_config.pool_size

--local red = redis:new()
--red:set_timeout(timeout)


local delay = 2

local _M = {}

function _M.make_approval_token(emp_no,form_id)

	if utils.chk_is_null(emp_no,form_id) then
		local msg = "emp_no,form_id不能爲空."
		return 501,nil,msg
	end

	local token = "approval-"..uuid()

	local red = redis:new()
	red:set_timeout(timeout)
	local result, err = red:connect(host,port)
	if not result or err then
        ngx.log(ngx.ERR,"failed to connect: "..err)
        return 502,nil,err
    end

    local val = cjson.encode({emp_no = emp_no,
    						form_id = form_id})

    ngx.log(ngx.DEBUG,"set val OK:"..val)

    local result, err = red:setex(token,86400,val)
    if not result then
        ngx.log(ngx.ERR,"failed to set key: ", err)
        return 503,nil,err
    end

    ngx.log(ngx.DEBUG,"set OK:"..token)

    local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
    if not ok then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return 504,nil,err
    end

    return 200,token,"sucess"
end

function _M.send_mail_instant(mail_info)
    local mail = mail_info.mail_to --收件人
    local attach = mail_info.attach --  郵件附件名字\path /opt/vssas/files/
    local subject = mail_info.mail_subject  --郵件主題
    local content = mail_info.content --郵件內容

    local attach_content
    local file
    local file_size
    local attach_path
    local attach_name
    local attach_info = {}

    -- 有附件
    if not utils.chk_is_null(attach) or type(attach) ~= "table" then
        for i=1,#attach,1 do
            attach_path = attach[i].path
            attach_name = attach[i].name
            file = io.open(attach_path..attach_name,"r")
            attach_content = file:read("*a")
            file_size = file:seek("end")
            ngx.log(ngx.DEBUG,"-------------------")
            io.close(file)

            attach_content = ngx.encode_base64(attach_content)
            table.insert(attach_info,{attach_name = attach_name,attach_content = attach_content})
        end
    end

    local request_body = cjson.encode{
        token = config.smtp_token,
        data = {
            rcpts = {mail},
            subject = subject,
            content = content,
            attach = (#attach_info==0) and "" or attach_info
        }
    }

    local response_body = {}

    local result, code, response_headers = http.request{
      url = config.smtp_sv.url,
      method = "POST",
      headers =
        {
            ["Content-Type"] = "application/json; charset=utf-8";
            ["Content-Length"] = string.len(request_body);
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
    }

    ngx.log(ngx.DEBUG,result)  -- 1
    ngx.log(ngx.DEBUG,code)  -- 200
    local res_body = cjson.encode(response_body)

    if result and code == 200 then
        ngx.log(ngx.DEBUG,cjson.encode(response_body)) --返回結果
        return {
            rv = 200,
            msg = "success",
            data = {send_time = os.date("%Y-%m-%d %H:%M:%S"),
                    res = "郵件 to "..mail .. "發送成功."}
        }
    end

    return {
        rv = 500,
        msg = res_body
    }
end

return _M
