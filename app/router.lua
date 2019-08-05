
local router_config = require("app.router_config")

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 2)

function _M:init_config()
    return router_config
end

function _M:load(app)

    for project , modules in pairs(self:init_config()) do
        for _ , groups in pairs(modules)do
            local uri = groups.uri
            local router = groups.router
            app:use(uri,require(router))--重置密碼
        end
    end
end

return _M