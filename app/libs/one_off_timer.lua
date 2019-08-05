local api_model = require("app.model.api")
local cjson = require("cjson")
local utils = require("app.libs.utils")
local shared_data = ngx.shared.shared_data
local delay = 0
local _M = {}

function _M.set_api_defined()
	local api_defined, err = api_model:query_api_defined_tb()
	if not api_defined or err then 
		api_defined = ""
	end
	--[[
	for i=1,#api_defined,1 do
		local main_params = api_defined[i].main_params
		local params = api_defined[i].params
		local headers = api_defined[i].headers

		if utils.chk_is_null(main_params) then 
			main_params = cjson.decode(main_params)
			api_defined[i].main_params = main_params
		end

		if utils.chk_is_null(params) then 
			params = cjson.decode(params)
			api_defined[i].params = params
		end

		if utils.chk_is_null(headers) then 
			params = cjson.decode(headers)
			api_defined[i].headers = headers
		end
	end
	]]--
	shared_data:set("api_info",cjson.encode(api_defined))
end

function _M.get_api_defined()
	local flag = shared_data:get("api_info_change")

	local api_info = shared_data:get("api_info")

	if tonumber(flag) == 1 then 
		_M.set_shared_data_api()
	end

	return cjson.decode(api_info)
end

return _M