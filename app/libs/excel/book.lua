local excel_sheet = require("app.libs.excel.sheet")
local utils = require("app.libs.utils")
local config = require("app.config.".. ngx.shared.config:get("config"))
local cjson = require("cjson")
local attach_model = require("app.model.attachments")
local filedir_temp = config.upload_config.dir
local slower = string.lower
local _M = {}

local s_find = string.find
local s_sub = string.sub
local s_gsub = string.gsub

function _M:new(file)
    
    if file.success and file.filename and slower(file.extname) == "xlsx" then
        local instance = {}
        instance.file = file
        instance.sheets = {}
		local co = coroutine.create(function (file)
            local proc = io.popen('./exec/xlsx2lua --no-pretty --skip-empty-row '..file.path)
            local stdout = proc:read('*a')
            proc:close()
            
            --智能商務系統專用
            if file.flag == 'ssub' then
                local intercept = s_sub(stdout,-3,-1)
               
                if intercept == '}}}' then
                    stdout = s_gsub(stdout,'}}}','}}}}}')
                end        

                if utils.chk_is_null(stdout) or not loadstring(stdout) then
                    return nil,'文件不能爲空'
                end
            
                local book = loadstring(stdout)()
                local fingerprint = ngx.md5(cjson.encode(book))
                instance.file.fingerprint = fingerprint

                for _,v in pairs(book['sheets']) do
                     local sheet = {}
                     sheet.name = v['name']
                     sheet.ins = excel_sheet:new1(v['cells'])

                     table.insert( instance.sheets, sheet)
                end
            else
                if utils.chk_is_null(stdout) or not loadstring(stdout) then
                    return nil,'文件不能爲空'
                end
                local book = loadstring(stdout)()
                local fingerprint = ngx.md5(cjson.encode(book))
                instance.file.fingerprint = fingerprint

                for _,v in pairs(book['sheets']) do
                     local sheet = {}
                     sheet.name = v['name']
                     sheet.ins = excel_sheet:new(v['cells'])

                     table.insert( instance.sheets, sheet)
                end
            end
            
        end)
        coroutine.resume(co,file)
        setmetatable(instance, { __index = self})
        return instance
    else
        return nil,'文件必須為xlsx類型'
   end
end

function _M:get_sheet_by_name(sheet_name)
    if utils.chk_is_null(sheet_name) then
        return nil,'sheet_name不能为空'
    end
    for _,v in pairs(self.sheets) do
        if v.name == sheet_name then
            return v.ins
        end
    end

    return nil,'未找到该工作表'
end

function _M:get_sheet_by_index(sheet_index)
    if utils.chk_is_null(sheet_index) then
        return nil,'sheet_index不能為空'
    end
    local sheet = self.sheets[sheet_index]
    if not sheet then
        return nil,'未找到该工作表'
    end
    return sheet.ins
end

function _M:get_sheets()
    return self.sheets
end

function _M:save(file_dir)
    local disk_filename = self.file.filename
    local osexe,a,b,c = os.execute("mv -f " .. filedir_temp .."/" ..
                                   disk_filename .. " " .. file_dir .. "/" .. 
                                   disk_filename)
    if osexe then
        return true
    else
        return nil,'移动文件失败'
    end
end

function _M:save_insert(file_dir,file_path,author,description)
    local f_file = io.open(self.file.path, "r")
	local filesize = f_file:seek("end")
    io.close(f_file)
    local res, err = self:save(file_dir)
    if not res then
        return false, err
    end
    local res, err = attach_model:insert(utils.trim(self.file.origin_filename), 
                     self.file.filename, slower(self.file.extname), 
                     author, description or '', self.file.fingerprint, 
                     file_path, filesize)
    if err then
        return false,'插入失敗'
    end
    return true,res
end

return _M