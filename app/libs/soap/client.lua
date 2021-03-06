local assert, tonumber, tostring, pcall = assert, tonumber, tostring, pcall
local concat = require("table").concat
local cjson = require "cjson"
local ltn12 = require("ltn12")

local zhttp = require("resty.http")
--local resolver = require "resty.dns.resolver"


local soap = require("app.libs.soap.soap")
local xml2lua = require("xml2lua")
--Uses a handler that converts the XML to a Lua table
local tree = require("xmlhandler.tree")


local M = {
	_COPYRIGHT = "Copyright (C) 2004-2013 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 3.0 client",

	-- Support for SOAP over HTTP is default and only depends on LuaSocket
	http = require("socket.http"),
}

local xml_header_template = '<?xml version="1.0"?>'

local mandatory_soapaction = "Field `soapaction' is mandatory for SOAP 1.1 (or you can force SOAP version with `soapversion' field)"
local mandatory_url = "Field `url' is mandatory"
local invalid_args = "Supported SOAP versions: 1.1 and 1.2.  The presence of soapaction field is mandatory for SOAP version 1.1.\nsoapversion, soapaction = "

local suggested_layers = {
	http = "socket.http",
	https = "ssl.https",
}

---------------------------------------------------------------------
-- Call a remote method.
-- @param args Table with the arguments which could be:
-- url: String with the location of the server.
-- soapaction: String with the value of the SOAPAction header.
-- namespace: String with the namespace of the elements.
-- method: String with the method's name.
-- entries: Table of SOAP elements (LuaExpat's format).
-- header: Table describing the header of the SOAP-ENV (optional).
-- internal_namespace: String with the optional namespace used
--  as a prefix for the method name (default = "").
-- soapversion: Number with SOAP version (default = 1.1).
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function M.call(args)

	local xml_header = xml_header_template
	if args.encoding then
		xml_header = xml_header:gsub('"%?>', '" encoding="'..args.encoding..'"?>')
	end
	local request_body = xml_header..soap.encode(args)
	local request_sink, tbody = ltn12.sink.table()
	local headers = {
		["Content-Type"] = "application/soap+xml",
		["content-length"] = tostring(request_body:len()),
	}
	if args.headers then
		for h, v in pairs (args.headers) do
			headers[h] = v
		end
	end
	local url = {
		url = assert(args.url, mandatory_url),
		method = "POST",
		source = ltn12.source.string(request_body),
		sink = request_sink,
		headers = headers,
	}

	local protocol = url.url:match"^(%a+)" -- protocol's name
	local mod = assert(M[protocol], '"'..protocol..'" protocol support unavailable. Try soap.client.'..protocol..' = require"'..suggested_layers[protocol]..'" to enable it.')
	local request = assert(mod.request, 'Could not find request function on module soap.client.'..protocol)

	local one_or_nil, status_code, headers, receive_status = request(url)
	local body = concat(tbody)

	if one_or_nil == nil then
		local error_msg = "Error on response: "..tostring(status_code).."\n\n"..tostring(body)
		local extra_info = {
			http_status_code = status_code,
			http_response_headers = headers,
			receive_status = receive_status,
			body = body,
		}
		return nil, error_msg, extra_info
	end

	local handler = tree:new()
	local parser = xml2lua.parser(handler)
	parser:parse(body)
	-- if not pcall(parser:parse(,body)) then
	-- 	return nil,'xml2lua false'
	-- end
	
	return handler.root

end

function M.call_ex(args)
	local xml_header = xml_header_template
	if args.encoding then
		xml_header = xml_header:gsub('"%?>', '" encoding="'..args.encoding..'"?>')
	end

	local request_body = xml_header..soap.encode(args)

	local headers = {
		["Content-Type"] = "application/soap+xml",
		["content-length"] = tostring(request_body:len()),
	}
	if args.headers then
		for h, v in pairs (args.headers) do
			headers[h] = v
		end
	end

	local httpc = zhttp.new()

	timeout = timeout or 30000
	httpc:set_timeout(timeout)

	local res, err_ = httpc:request_uri(assert(args.url, mandatory_url), {
        method = "POST",
        body = request_body,
        headers =  headers
	})
	
	if not res then
        return nil, err_
   else
	  if res.status == 200 then
				local handler = tree:new()
				local parser = xml2lua.parser(handler)
				parser:parse(res.body)
				return handler.root
           else
                return nil, err_
           end
    end
end
---------------------------------------------------------------------
return M
