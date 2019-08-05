local config = require("app.config.".. ngx.shared.config:get("config"))
local cjson = require("cjson")
local pdf = require("app.common.pdf")
local template = require ("resty.template")
local user_model = require("app.model.user")
local approval_model = require("app.model.approval_lm")
local emp_model = require("app.model.emp")
local redis = require("resty.redis")
local mail = require("app.libs.mail")
local utils = require("app.libs.utils")

local host = config.redis.connect_config.host
local port = config.redis.connect_config.port
local timeout 	= config.redis.timeout
local pool_size = config.redis.pool_config.pool_size
local max_idle_timeout = config.redis.pool_config.max_idle_timeout
local self_url = config.server_self.url
local ssub = string.sub
local sfind = string.find
local sformat = string.format
local os_date = os.date
local ngx_today = ngx.today
local spawn = ngx.thread.spawn
local timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local delay = 2
local find = ngx.re.find
local t_rev = table.remove
local pcall = pcall
local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0,4)
            
local function deal_electeonic_mail(data,attachments,mail_flag)
    local mail_subject 
    local view
    local process_now_no
    local process_now_name
    local form_id = data.form_id
    local filesname = new_tab(8,0)
    local apply_info,err = approval_model:query_apply_info_by_id(form_id)
	if not apply_info or err then
		log(ERR,"沒有找到表單信息，請檢查.")
		return 
    end
    local promoter_info,err = emp_model:query_userinfo_by_emp_no(apply_info.promoter)
	if not promoter_info or err then
		log(ERR,"沒有承辦人信息,請檢查.")
		return 
    end
    -- ngx.log(ngx.ERR,"數據爲:",cjson.encode(data))
    -- ngx.log(ngx.ERR,"數據爲1:",cjson.encode(attachments))
    -- ngx.log(ngx.ERR,"數據爲2:",cjson.encode(mail_flag))
    local promoter_name = promoter_info.name
    if mail_flag == "finish" then
        mail_subject = "【電子簽核系統】"..apply_info.subject .." 審批完成通知(帶附件)！"
        view = "app/views/mail_template/signFinishMail.html"
        process_now_no = apply_info.promoter
        process_now_name = promoter_name
	    local attach = data.attach_name 
        local user_attach = attachments 
	    local logo_dir = config.logo_pdf_path.dir
        local static_path = config.upload_files.dir
	    local form_code = data.form_code
        local attach_content
        local file_size = 0
	    local date

	    --取日期的字串（格式：YYYYMMDD）
	    if utils.chk_is_null(form_id, form_code) then
	    	date = ngx_today("%Y%m%d")
	    else
	    	local index = find(form_code, "-")
	    	date = ssub(form_code, 1, index - 1)
	    end

	    local attach_dir_fmt = "%s/%s/%s"
        local attach_dir = sformat(attach_dir_fmt, static_path, date, form_code)
    
        --创建附件存放的路径
        local ok, err = utils.batch_mkdir(attach_dir)   
    
        if not ok then
            log(ERR,"新建日期文件夾失敗")
            return 
        end
    
         local attach_full_file_path = attach_dir .. "/e-" .. attach
    
        --需要生成pdf文件的html来源
        local url_fmt = "%s/npi-approvals/%s?simulation_employee_no=%s&htmltopdf=1"
        local url = sformat(url_fmt, self_url, form_id, data.emp_no)
        local ok, err = pdf.html_to_pdf(url, attach_full_file_path)
        if not ok then
            log(ERR,"頁面保存失敗")
            return 
	    end			

         -- 是否有用戶自帶附件，沒有
        if not user_attach or #user_attach == 0 then
            local output_file = attach_dir.."/"..attach
            local ok , err = pdf.watermark(attach_full_file_path, logo_dir, output_file )
            if not ok then
                return 
            end
        
	    	filesname[1]={attach_name = attach_dir.."/"..attach}
        else
             -- 疊加到現有附件後面 e-2017
            if config.mail_attach_send == "concat" then
                local wait_combined_files = new_tab(8,0)
                wait_combined_files[1] = attach_full_file_path
                for i=1,#user_attach,1 do
                     file_size = file_size + user_attach[i].attach_size
                    if file_size < 1000*1000*10 and ssub(user_attach[i]['attach_name'],(sfind(user_attach[i]['attach_name'],".(%w+)$"))+1,-1) ~= 'xlsx' then
                        wait_combined_files[i+1] = attach_dir .. "/" .. user_attach[i].attach_code
                    end
                end
                local output_file = attach_dir .. "/m-"..attach
                local ok, err = pdf.combined(wait_combined_files, output_file) 
                if not ok then
                    log(ERR,"頁面疊加失敗")
                    return 
                end
            
                local source_file = output_file
                local output_file = attach_dir.."/"..attach
                local ok, err = pdf.watermark(source_file, logo_dir, output_file )
            
                if not ok then
                    log(ERR,"頁面渲染失敗")
                    return 
                end
            
                filesname[1] = {attach_name = attach_dir.."/"..attach}
            else
            
                local output_file = attach_dir .. "/" .. attach
                local ok, err = pdf.watermark(attach_full_file_path, logo_dir, output_file )
                if not ok then
                    log(ERR,"頁面渲染失敗")
                    return 
                end
	    		filesname[1] = {attach_name = attach_dir .. "/" ..attach}
                for i = 1, #user_attach, 1 do
                    attach = user_attach[i].attach_code
                    local ok, err = pdf.watermark(attach_dir .. "/" .. attach, 
                                                    logo_dir, 
                                                    attach_dir .. "/e-" .. attach)
                    if not ok then
                        log(ERR,"頁面渲染失敗")
                        return 
                    end
                
                    filesname[i+1] = {attach_name = attach_dir .."/e-"..attach}
                    
                end
	    	end	
        end
    else
        if utils.chk_is_null(data.process_now_no) or utils.chk_is_null(data.process_now_name) then
            local process_next_info,err = approval_model:query_process_next_by_process(apply_info.process_now,form_id)
		    if not process_next_info or err then
		    	msg = "沒有找到下一簽核人員工號信息."
		    	return 509,nil,err or msg
            end
            process_now_no = process_next_info[1].approve_empno 
            process_now_name = process_next_info[1].approve_empname
        else
            process_now_no = data.process_now_no 
            process_now_name = data.process_now_name
        end
          

        if not process_now_no then
            msg = "沒有找到下一簽核人員工號信息."
            return 509,nil,err or msg
        end
        if mail_flag == "reject_to_applicant" then 
            mail_subject = "【電子簽核系統】"..apply_info.subject .."退件通知！"
            view = "app/views/mail_template/rejectToApplicantMail.html"
        end
        if mail_flag == "reject_to_approval" then 
            mail_subject = "【電子簽核系統】"..apply_info.subject .."退件通知！"
            view = "app/views/mail_template/rejectToAuditorMail.html"
        end
        if mail_flag == "invitation" then 
            mail_subject = "【電子簽核系統】"..apply_info.subject .."簽核邀請！"
            view = "app/views/mail_template/invitationSignMail.html"
        end
        if mail_flag == "template" then 
            mail_subject = "【電子簽核系統】"..apply_info.subject .."確定簽核流程邀請！"
            view = "app/views/mail_template/invitationSignMail.html"
        end
    end
    local mail_info,err = user_model:query_mail_by_emp_no(process_now_no)
    if not mail_info or err then
		log(ERR,"沒有找到"..process_now_no.."的郵箱信息,請檢查.")
		return 
    end
    local mail_to = mail_info.mail_notification
    local code,mail_token,err = mail.make_approval_token(process_now_no,form_id)
    if code ~= 200 then
    	return code,nil,msg
    end
    -- ngx.log(ngx.ERR,"=========:mail_to",mail_to)
    -- ngx.log(ngx.ERR,"=========:mail_to",mail_flag)
    -- ngx.log(ngx.ERR,"=========:mail_to",view)
    -- ngx.log(ngx.ERR,"=========:mail_to",mail_subject)

    -- log(ERR,promoter_name)
    -- log(ERR,apply_info.submit_at)
    -- log(ERR,apply_info.subject)
    -- log(ERR,self_url)
    -- log(ERR,form_id)
    
    local content_pre = "<p>哎呀，內容加載錯誤了(〒︿〒)</p> \n "
    local func = template.compile(view)
    local content = func{ approval_name = process_now_name,
                        submit_at = apply_info.submit_at,
                        reject_reason = data.reason,
                        approve_reject_name = data.emp_name,
                        subject = apply_info.subject,
                        promoter = promoter_name,
                        pre_approve_time = data.pre_approve_time,
                        approval_time = os_date("%Y-%m-%d %H:%M:%S"),
                        link_auth = self_url .. "/auth/login?Lw==",
                        link = self_url .. "/approvals/"..form_id.."?mail_token="..mail_token
                      } or content_pre
    local mail_param = cjson.encode{
        mail_to = mail_to,
		mail_subject = mail_subject,
		content = content, --內容
		filesname = filesname
    }
    -- log(ERR,mail_to)
	-- log(ERR,content)
	-- log(ERR,view)
    
    local red = redis:new()
    red:set_timeout(timeout)

    local ok, err = red:connect(host, port)
    if not ok or err then
        log(ERR,"failed to connect: "..err)
        return
    end
    local result, err = red:rpush("pending_mail_source",mail_param)
    if not result then
        log(ERR,"failed to set key: ",err)
        return 
    end
 
	return 
end

function _M:start(self)

    local red = redis:new()
    red:set_timeout(timeout)

    local ok, err = red:connect(host, port)
    if not ok or err then
        log(ERR,"failed to connect: "..err)
        return
    end
    
    local electeonic_mail,err = red:lpop("electeonic_mail")
    while electeonic_mail and 
          electeonic_mail ~= ngx.null and 
          electeonic_mail ~= "" and 
          electeonic_mail ~= nil do
        local electeonic_mail_info = cjson.decode(electeonic_mail)
        spawn(deal_electeonic_mail,electeonic_mail_info.data,
        electeonic_mail_info.attachments,electeonic_mail_info.mail_flag)
        electeonic_mail,err = red:lpop("electeonic_mail")

    end
    local ok, err = red:set_keepalive(max_idle_timeout, pool_size)
    if not ok or err then
        ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
        return
    end
    local ok, err = timer(delay, self.start, self)
    if not ok then
      ngx.log(ngx.ERR, "failed to create the timer: ", err)
      return
    end
end

return _M
            