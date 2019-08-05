local excel_book = require("app.libs.excel.book")
local lor = require("lor.index")
local cjson = require("cjson")
local excel_router = lor:Router()

local success_cb = function(vals)
    ngx.log(ngx.ERR,'success'..cjson.encode(vals))
end

local false_cb = function(vals)
    ngx.log(ngx.ERR,'false'..cjson.encode(vals))
end

excel_router:post('',function(req,res,next)
    local file = req.file
    local book,err = excel_book:new(file)
    -- 獲取索引為1的工作薄
    local sheet,err = book:get_sheet_by_index(1)
    -- 頭部檢查設置
    sheet:header_verify(function(head)
        ngx.log(ngx.ERR,cjson.encode(head))
        --out: ["線體","工號","姓名","DL類型","人力占比","崗位"]
    end)
    -- 設置映射關係
    local result,err = sheet:set_header_map(
           {name='姓名',
            no='工號'}
    )
    -- for _,v in pairs(sheet:get_data()) do
    --     -- 空值檢查
    --     local result,err = sheet:chk_null(v,{'name','no'},success_cb,false_cb)
    --     --out: false[{"key":"no","data":""}]

    --     --格式檢查
    --     local result,err = sheet:chk_format(v,{'name','no'},'^萬',success_cb,false_cb)
    --     --out: false[{"key":"no","data":""}]

    --     --存在檢查
    --     local result,err = sheet:chk_str_in_table(v,{'name'},{'萬科','aaa'},success_cb,false_cb)
    --     --out: success[{"key":"name","data":"萬科"}]
    -- end
    --保存并插入數據庫
    local result,msg = book:save_insert('/opt/vssas/app/static/files/pdm_std_profiles',
                                        '/static/files/pdm_std_profiles','F2846095')
        -- result:true  msg:925
    ngx.log(ngx.ERR,msg)
end)

return excel_router