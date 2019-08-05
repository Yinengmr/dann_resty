local resp = require("app.libs.response.resp")
local cjson =require("cjson")

local CODE_PARAMS = require("app.config.code_parameters")

local table = {msg='asafasf%{name}',msg_args={name='zdp'}}

local res = resp:ok()
-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
res = resp:ok('abc')
-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
res = resp:ok({msg='abc%{age}',msg_args={age=18}})
-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
res = resp:err()
-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
res = resp:err(502)
-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
res = resp:err('abc')
-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
res = resp:err(501,'abc')
-- print('rv = '..res.rv..',msg = '..res.msg)

ngx.say(cjson.encode(res))
res = resp:err({rv=503,msg='abc%{name}',msg_args={name='zdp'}})

-- print('rv = '..res.rv..',msg = '..res.msg)
ngx.say(cjson.encode(res))
