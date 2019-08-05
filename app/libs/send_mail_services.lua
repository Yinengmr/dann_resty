local ltn12 = require("ltn12")
local cjson = require("cjson")
local redis = require("resty.redis")
local http 	= require("socket.http")

local utils = require("app.libs.utils")

local pdf = require("app.common.pdf")

local config = require("app.config.".. ngx.shared.config:get("config"))
local self_url = config.server_self.url
local tinsert = table.insert
local ngx_today = ngx.today
local ssub = string.sub
local sformat = string.format
local slen = string.len
local encode_base64 = ngx.encode_base64
local delay = 2

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 2)

_M.new_tab = new_tab
_M._VERSION = "0.01"

local function send_mail(mail_info)
    local mail = mail_info.mail_to --收件人
    -- local attach = mail_info.attach_name --  郵件附件
    -- local user_attach = mail_info.attachments -- 用戶自己的附件
    local subject = mail_info.mail_subject  --郵件主題
    local content = mail_info.content --郵件內容
    -- local form_id = mail_info.form_id --表單id
    -- local form_code = mail_info.form_code --表單單號
    -- local emp_no = mail_info.emp_no
    local filesname = mail_info.filesname or {}
    -- local logo_dir = config.logo_pdf_path.dir
    -- local static_path = config.upload_files.dir

    local attach_content
    local file_size
    local attach_info = {}
    -- local date
 
    --[[    --取日期的字串（格式：YYYYMMDD）
        if utils.chk_is_null(form_id, form_code) then
            date = ngx_today("%Y%m%d")
        else
            local index = ngx.re.find(form_code, "-")
            date = ssub(form_code, 1, index - 1)
        end


        --检查是否有单个附件
        if attach and not utils.chk_is_null(attach) then  -- e-201713.pdf
            
            local attach_dir_fmt = "%s/%s/%s"
            local attach_dir = sformat(attach_dir_fmt, static_path, date, form_code)

            --创建附件存放的路径
            local ok, err = utils.batch_mkdir(attach_dir)   

            if not ok then
                return 590, "新建日期文件夾失敗. (" .. err .. ")"
            end

            local attach_full_file_path = attach_dir .. "/e-" .. attach

            --需要生成pdf文件的html来源
            local url_fmt = "%s/approval/%s?simulation_employee_no=%s"
            local url = sformat(url_fmt, self_url, form_id, emp_no)


            local ok, err = pdf.html_to_pdf(url, attach_full_file_path)
            if not ok then
                return { rv = 580, 
                        msg = "頁面保存失敗. (" .. err ..")" }
            end

            file_size = utils.file_size(attach_full_file_path);

            -- 是否有用戶自帶附件，沒有
            if not user_attach or #user_attach == 0 then
                local output_file = attach_dir.."/"..attach
                local ok , err = pdf.watermark(attach_full_file_path, logo_dir, output_file )
                
                if not ok then
                    return {rv = 581,msg = "頁面渲染失敗. (" .. err .. ")" }
                end

                local ok, err = utils.file_remove(attach_full_file_path)

                if not ok then
                    return {rv = 582, msg = "刪除文件失敗. (" .. err ..")"}
                end

                file_size =  utils.file_size(output_file)
                attach_content = utils.file_content(output_file)
                if file_size < 1000*1000*10 then
                    attach_content = ngx.encode_base64(attach_content)
                    table.insert(attach_info,{ attach_name 	  = attach, 
                                            attach_content = attach_content})
                end
            else
                -- 疊加到現有附件後面 e-2017
                if config.mail_attach_send == "concat" then
                    local wait_combined_files = { attach_full_file_path }

                    for i=1,#user_attach,1 do
                        file_size = file_size + user_attach[i].attach_size
                        if file_size < 1000*1000*10 then
                            table.insert(wait_combined_files, 
                                        attach_dir .. "/" .. user_attach[i].attach_code )
                        end
                    end
                    
                    local output_file = attach_dir .. "/m-"..attach
                    local ok, err = pdf.combined(wait_combined_files, output_file) 
                    if not ok then
                        return {rv = 583,msg = "頁面疊加失敗. (" .. err .. ")" }
                    end

                    local source_file = output_file
                    local output_file = attach_dir.."/"..attach
                    local ok, err = pdf.watermark(source_file, logo_dir, output_file )
                    
                    if not ok then
                        return {rv = 584,msg = "頁面渲染失敗.(" .. err .. ")" }
                    end
                    
                    local ok, err = utils.file_remove(attach_full_file_path)
                    local ok, err = utils.file_remove(source_file)

                    if not ok then
                        return {rv = 585, msg = "刪除文件失敗."}
                    end
                    
                    file_size = utils.file_size(output_file)
                    attach_content = ngx.encode_base64(utils.file_content(output_file))

                    table.insert(attach_info, { attach_name    = attach, 
                                                attach_content = attach_content})
                -- user_attach取出來內容attach_code,名字attach_name, 作爲額外獨立附件
                else

                    local output_file = attach_dir .. "/" .. attach
                    local ok, err = pdf.watermark(attach_full_file_path, logo_dir, output_file )
                    if not ok then
                        return {rv = 586,msg = "頁面渲染失敗."}
                    end

                    local ok, err = utils.file_remove(attach_full_file_path)
                    if not ok then
                        return {rv = 587,msg = "刪除文件失敗."}
                    end

                    file_size = utils.file_size(output_file)
                    attach_content = utils.file_content(output_file)
                    
                    attach_content = ngx.encode_base64(attach_content)
                    table.insert(attach_info,{  attach_name    = attach,
                                                attach_content = attach_content})

                    for i = 1, #user_attach, 1 do
                        attach = user_attach[i].attach_code
                        local ok, err = pdf.watermark(attach_dir .. "/" .. attach, 
                                                    logo_dir, 
                                                    attach_dir .. "/e-" .. attach)
                        if not ok then
                            return { rv = 588,
                                    msg = "頁面渲染失敗."}
                        end

                        attach_content = ngx.encode_base64(utils.file_content(attach_dir .. "/e-" .. attach))
                        attach = user_attach[i].attach_name
                        file_size = file_size + user_attach[i].attach_size

                        -- file_size 不能超過 10M
                        if file_size < 1000*1000*10 then
                            table.insert(attach_info, { attach_name    = attach,
                                                        attach_content = attach_content})
                        end
                    end

                    ngx.log(ngx.DEBUG,"-------------------", #attach_info)
                end
            end
        end]]

    for i = 1,#filesname do
        attach_content = encode_base64(utils.file_content(filesname[i].attach_name))
        file_size = utils.file_size(filesname[i].attach_name)
        if file_size < 1000*1000*10 then
            local str = utils.string_split(filesname[i].attach_name,"/")
            local filename = str[#str]
            tinsert(attach_info,{attach_name = filename,
                                        attach_content = attach_content})
        end
    end
    local request_body = cjson.encode{
        token = config.smtp_token,
        data = {
            rcpts   = { mail },
            subject = subject,
            content = content,
            attach  = ( #attach_info == 0 ) and "" or attach_info
        }
    }

    ngx.log(ngx.DEBUG,"-------------",slen(request_body))

    local response_body = {}

    local result, code, response_headers = http.request{
      url = config.smtp_sv.url,
      method = "POST",
      headers =
        {
            ["Content-Type"] = "application/json; charset=utf-8";
            ["Content-Length"] = slen(request_body);
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
            rv   = 200,
            msg  = "success",
            data = {send_time = os.date("%Y-%m-%d %H:%M:%S"),
                    res = "郵件 to "..mail .. "發送成功."}
        }
    end

    return {
         rv = 500,
        msg = res_body
    }
end

function _M:start(self)

    local host = config.redis.connect_config.host
    local port = config.redis.connect_config.port
    local timeout 	= config.redis.timeout
    local pool_size = config.redis.pool_config.pool_size
    local max_idle_timeout = config.redis.pool_config.max_idle_timeout
    
    local red = redis:new()
    red:set_timeout(timeout)

    local ok, err = red:connect(host, port)
    if not ok or err then
        ngx.log(ngx.ERR,"failed to connect: "..err)
        return
    end

    local mail_info, err = red:lpop("pending_mail_source")

    while mail_info and 
          mail_info ~= ngx.null and 
          mail_info ~= "" and 
          mail_info ~= nil do

         ngx.log(ngx.DEBUG, mail_info)

         local mail = cjson.decode(mail_info)

         ngx.thread.spawn(send_mail, mail)

        mail_info, err = red:lpop("pending_mail_source")
    end

    local ok, err = red:set_keepalive(max_idle_timeout, pool_size)
    if not ok or err then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return
    end

    local ok, err = ngx.timer.at(delay, self.start, self)
    if not ok then
      ngx.log(ngx.ERR, "failed to create the timer: ", err)
      return
    end

end

return _M

