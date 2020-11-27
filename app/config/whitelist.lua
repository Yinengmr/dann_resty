
-- 白名單配置：不需要登錄即可訪問；除非要二次開發，否則不應更改
local whitelist = {
    -- "^/m1",
    -- "^/m2",
    -- "^/test",

    -- "^/app/v1/auth/token_refresh$",
    -- "^/app/v1/auth/refresh_token$",
    "^/jwt",
    "^/login$",
}
return whitelist