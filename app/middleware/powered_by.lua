local config = require("app.config.".. ngx.shared.config:get("config"))

local allow_cross_domain = config.allow_cross_domain


return function(text)

	return function(req, res, next)

	    res:set_header('X-Powered-By', text)
			if allow_cross_domain then
			local header_origin = req.headers["origin"]
			ngx.header['Access-Control-Allow-Origin'] = header_origin or 'null'  --'*'
		    --res:set_header('Access-Control-Allow-Origin','*') -- 跨域調試用
		    res:set_header('Access-Control-Allow-Methods','GET, POST, OPTIONS')
			res:set_header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept')
			res:set_header('Access-Control-Allow-Credentials','true');
			end
	    -- res:set_header('If-Modified-Since','0');
	    -- res:set_header('Cache-Control','no-cache');
	    --res:set_header('Access-Control-Allow-Origin',ngx.req.get_headers()["Origin"]) -- 跨域調試用
	    --res:set_header('Access-Control-Allow-Methods','GET, POST, OPTIONS')
	    --res:set_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')

		--res:set_header('Access-Control-Allow-Headers','x-requested-with');
		--res:set_header('Access-Control-Max-Age','86400');
		--res:set_header('Access-Control-Allow-Credentials','true');
		--res:set_header('Access-Control-Allow-Headers','x-requested-with,content-type');
		--res:set_header('Access-Control-Allow-Headers','Origin, No-Cache, X-Requested-With, If-Modified-Since, Pragma, Last-Modified, Cache-Control, Expires, Content-Type, X-E4M-With');

		next()
	end

end
