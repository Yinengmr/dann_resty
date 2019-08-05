local config = require("app.config.".. ngx.shared.config:get("config"))
local http = require("socket.http")
local ltn12 = require("ltn12")
local utils = require("app.libs.utils")
local cjson = require("cjson")
local redis = require("resty.redis")

local random = require "resty.random".bytes
local self_url = config.server_self.url
local delay = 2
local delay_1 = 0
local set_shared_data_api = require("app.libs.one_off_timer").set_api_defined

local function send_mail(mail_info)
	local mail = mail_info.mail_to --收件人
	local attach = mail_info.attach_name --  郵件附件
	local user_attach = mail_info.attachments -- 用戶自己的附件
	local subject = mail_info.mail_subject  --郵件主題
	local content = mail_info.content --郵件內容
	local form_id = mail_info.form_id --表單id
	local form_code = mail_info.form_code --表單單號
	local emp_no = mail_info.emp_no

	local filedir = config.upload_files.dir
	local logodir = config.logo_pdf_path.dir

	local attach_content
	local file_size
	local attach_info = {}
	local date
	if utils.chk_is_null(form_id,form_code) then
		date = os.date("%Y%m%d")
	else
		-- date = string.sub(form_code,1,8)
		local index = ngx.re.find(form_code,"-")
		date = string.sub(form_code,1,index-1)
	end

	if attach and attach~=nil and attach~="" and attach ~=ngx.null then  -- e-201713.pdf
		local date_form,a,b,c = os.execute("/bin/sh ./mkdir_date.sh "..date .." ".. form_code)
		if not date_form then
			return 590,"新建日期文件夾失敗."
		end

		local attachdir = filedir.."/"..date.."/"..form_code

		local wk = '/opt/wkhtmltox/bin/wkhtmltopdf --enable-javascript '..
				'--javascript-delay 500 --debug-javascript --no-background '..
				'--margin-top 18.05 --margin-left 15.05 --margin-right 20.05 '..
				'--margin-bottom 10.05 --header-left "[title]"   '..
				'--footer-center "[page]/[toPage]" --header-spacing 5 --footer-spacing 5 '..
				'--load-error-handling ignore -g '.. self_url .."/approvals/"..
				form_id .."?simulation_employee_no="..emp_no .. " "
				.. attachdir.."/e-"..attach

		ngx.log(ngx.DEBUG,"--------------------",wk)
		local osexe,a,b,c = os.execute(wk)
		ngx.log(ngx.DEBUG,osexe,a,b,c)
		if not osexe then
			return {rv = 580,msg = "頁面保存失敗."}
		end

		local file = io.open(attachdir.."/e-"..attach,"r")
		file_size = file:seek("end")
		ngx.log(ngx.DEBUG,"-------------------")
		io.close(file)

		-- 是否有用戶自帶附件，沒有
		if not user_attach or #user_attach == 0 then
			local tk = "pdftk " .. attachdir.."/e-"..attach .." stamp " .. logodir ..
					   " output " .. attachdir.."/"..attach

			ngx.log(ngx.DEBUG,"--------------------",tk)
			local osexe,a,b,c = os.execute(tk)
			ngx.log(ngx.DEBUG,osexe,a,b,c)
			if not osexe then
				return {rv = 581,msg = "頁面渲染失敗."}
			end

			local del_e = "rm -rf " .. attachdir.. "/e-"..attach
			ngx.log(ngx.DEBUG,"--------------------",del_e)
			local osexe,a,b,c = os.execute(del_e)
			ngx.log(ngx.DEBUG,osexe,a,b,c)
			if not osexe then
				return {rv = 582,msg = "刪除文件失敗."}
			end

			local file = io.open(attachdir.."/"..attach,"r")
			attach_content = file:read("*a")
			file_size = file:seek("end")
			ngx.log(ngx.DEBUG,"-------------------")
			io.close(file)

			if file_size < 1000*1000*10 then
				attach_content = ngx.encode_base64(attach_content)
				table.insert(attach_info,{attach_name = attach,attach_content = attach_content})
			end
		else
			-- 疊加到現有附件後面 e-2017
			if config.mail_attach_send == "concat" then
				local cat = "pdftk "..attachdir.."/e-" ..attach
				local user_cat = " "
				for i=1,#user_attach,1 do
					file_size = file_size + user_attach[i].attach_size
					if file_size < 1000*1000*10 then
						user_cat = user_cat ..attachdir .. "/"..user_attach[i].attach_code .. " "
					end
				end
				-- 又變成
				cat = cat .. user_cat .. " cat output  "..attachdir .. "/m-"..attach
				ngx.log(ngx.DEBUG,"--------------------",cat)
				local osexe,a,b,c = os.execute(cat)
				ngx.log(ngx.DEBUG,osexe,a,b,c)
				if not osexe then
					return {rv = 583,msg = "頁面疊加失敗."}
				end

				local tk = "pdftk " .. attachdir.."/m-"..attach .." stamp " .. logodir ..
					   " output " .. attachdir.."/"..attach

				ngx.log(ngx.DEBUG,"--------------------",tk)
				local osexe,a,b,c = os.execute(tk)
				ngx.log(ngx.DEBUG,osexe,a,b,c)
				if not osexe then
					return {rv = 584,msg = "頁面渲染失敗."}
				end

				local del = "rm -rf " .. attachdir .. "/e-"..attach .. " " ..attachdir .. "/m-"..attach
				ngx.log(ngx.DEBUG,"--------------------",del)
				local osexe,a,b,c = os.execute(del)
				ngx.log(ngx.DEBUG,osexe,a,b,c)
				if not osexe then
					return {rv = 585,msg = "刪除文件失敗."}
				end

				local file = io.open(attachdir.."/"..attach,"r")
				attach_content = file:read("*a")
				file_size = file:seek("end")
				ngx.log(ngx.DEBUG,"-------------------")
				io.close(file)

				attach_content = ngx.encode_base64(attach_content)
				table.insert(attach_info,{attach_name = attach,attach_content = attach_content})
			-- user_attach取出來內容attach_code,名字attach_name, 作爲額外獨立附件
			else
				local tk = "pdftk " .. attachdir.."/e-"..attach .." stamp " .. logodir ..
					   " output " .. attachdir.."/"..attach

				ngx.log(ngx.DEBUG,"--------------------",tk)
				local osexe,a,b,c = os.execute(tk)
				ngx.log(ngx.DEBUG,osexe,a,b,c)
				if not osexe then
					return {rv = 586,msg = "頁面渲染失敗."}
				end

				local del_e = "rm -rf " .. attachdir.. "/e-"..attach
				ngx.log(ngx.DEBUG,"--------------------",del_e)
				local osexe,a,b,c = os.execute(del_e)
				ngx.log(ngx.DEBUG,osexe,a,b,c)
				if not osexe then
					return {rv = 587,msg = "刪除文件失敗."}
				end

				local file = io.open(attachdir.."/"..attach,"r")
				attach_content = file:read("*a")
				file_size = file:seek("end")
				ngx.log(ngx.DEBUG,"-------------------")
				io.close(file)

				attach_content = ngx.encode_base64(attach_content)
				table.insert(attach_info,{attach_name = attach,attach_content = attach_content})
				for i=1,#user_attach,1 do
					attach = user_attach[i].attach_code

					local tk = "pdftk " .. attachdir.."/"..attach .." stamp " .. logodir ..
					   " output " .. attachdir.."/e-"..attach

					ngx.log(ngx.DEBUG,"--------------------",tk)
					local osexe,a,b,c = os.execute(tk)
					ngx.log(ngx.DEBUG,osexe,a,b,c)
					if not osexe then
						return {rv = 588,msg = "頁面渲染失敗."}
					end

					local file = io.open(attachdir.."/e-"..attach,"r")
					attach_content = file:read("*a")
					io.close(file)

					attach_content = ngx.encode_base64(attach_content)
					attach = user_attach[i].attach_name
					file_size = file_size + user_attach[i].attach_size

					-- file_size 不能超過 10M
					if file_size < 1000*1000*10 then
						table.insert(attach_info,{attach_name = attach,attach_content = attach_content})
					end
				end
				ngx.log(ngx.DEBUG,"-------------------",#attach_info)
			end
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

	ngx.log(ngx.DEBUG,"-------------",string.len(request_body))

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

local function proccess_pool()

	local timeout = config.redis.timeout
	local host = config.redis.connect_config.host
	local port = config.redis.connect_config.port
	local max_idle_timeout = config.redis.pool_config.max_idle_timeout
	local pool_size = config.redis.pool_config.pool_size

	local red = redis:new()
	red:set_timeout(timeout)
	local result, err = red:connect(host,port)
	if not result or err then
	    ngx.log(ngx.ERR,"failed to connect: "..err)
	    return
	end

	local mail_info, err = red:lpop("pending_mail_source")

	while mail_info and mail_info ~= ngx.null
		   and mail_info ~= "" and mail_info ~= nil do

	 ngx.log(ngx.DEBUG,mail_info)

	 local mail = cjson.decode(mail_info)

	 ngx.thread.spawn(send_mail,mail)

	mail_info, err = red:lpop("pending_mail_source")
	end

	local ok, err = red:set_keepalive(max_idle_timeout,pool_size)
	if not ok or err then
	    ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
	    return
	end

	local ok,err = ngx.timer.at(delay, proccess_pool)
	if not ok then
	  ngx.log(ngx.ERR, "failed to create the timer: ", err)
	  return
	end

end

ngx.log(ngx.DEBUG,"start send_mail_service ...")
ngx.log(ngx.DEBUG,"start init_api_service ...")

if 0 == ngx.worker.id() then
    local ok,err = ngx.timer.at(delay, proccess_pool)
    local ok1, err1 = ngx.timer.at(delay_1, set_shared_data_api)

    if not ok then
        ngx.log(ngx.ERR, "failed to create the timer: ", err)
        return
  	end

	if not ok1 then
	    ngx.log(ngx.ERR, "failed to create the timer: ", err)
	    return
	end
end
