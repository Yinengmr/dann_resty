--- 中間件示例： 爲每個請求注入一些通用的變量
local lor = require("lor.index")
return function()
    return function(req, res, next)
        -- res.locals是一個table, 可以在這裏注入一些“全局”變量
        -- 這個示例裏注入app的名稱和版本號， 在渲染頁面時即可使用
        res.locals.app_name = "lor application"
        res.locals.app_version = lor.version or ""
        next()
    end
end
