
local assert, error, pairs, tonumber, tostring, type = assert, error, pairs, tonumber, tostring, type
local table = require"table"
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local string = require"string"
local gsub, strfind, strformat = string.gsub, string.find, string.format
local max = require"math".max

local tescape = {
	['&'] = '&amp;',
	['<'] = '&lt;',
	['>'] = '&gt;',
	['"'] = '&quot;',
	["'"] = '&apos;',
}
---------------------------------------------------------------------
-- Escape special characters.
---------------------------------------------------------------------
local function escape (text)
	return (gsub (text, "([&<>'\"])", tescape))
end

local tunescape = {
	['&amp;'] = '&',
	['&lt;'] = '<',
	['&gt;'] = '>',
	['&quot;'] = '"',
	['&apos;'] = "'",
}
---------------------------------------------------------------------
-- Unescape special characters.
---------------------------------------------------------------------
local function unescape (text)
	return (gsub (text, "(&%a+%;)", tunescape))
end

local serialize

---------------------------------------------------------------------
-- Serialize the table of attributes.
-- @param a Table with the attributes of an element.
-- @return String representation of the object.
---------------------------------------------------------------------
local function attrs (a)
	if not a then
		return "" -- no attributes
	else
		local c = {}
		if a[1] then
			for i = 1, #a do
				local v = a[i]
				c[i] = strformat ("%s=%q", v, a[v])
			end
		else
			for i, v in pairs (a) do
				c[#c+1] = strformat ("%s=%q", i, v)
			end
		end
		if #c > 0 then
			return " "..tconcat (c, " ")
		else
			return ""
		end
	end
end

---------------------------------------------------------------------
-- Serialize the children of an object.
-- @param obj Table with the object to be serialized.
-- @return String representation of the children.
---------------------------------------------------------------------
local function contents (obj)
	if not obj[1] then
		return ""
	else
		local c = {}
		for i = 1, #obj do
			c[i] = serialize (obj[i])
		end
		return tconcat (c)
	end
end

---------------------------------------------------------------------
-- Serialize an object.
-- @param obj Table with the object to be serialized.
-- @return String with representation of the object.
---------------------------------------------------------------------
serialize = function (obj)
	local tt = type(obj)
	if tt == "string" then
		return escape(unescape(obj))
	elseif tt == "number" then
		return obj
	elseif tt == "table" then
		local t = obj.tag
		assert (t, "Invalid table format (no `tag' field)")
		return strformat ("<%s%s>%s</%s>", t, attrs(obj.attr), contents(obj), t)
	else
		return ""
	end
end

---------------------------------------------------------------------
-- Add header element (if it exists) to object.
-- Cleans old header element anyway.
---------------------------------------------------------------------
local header_template = {
	tag = "soap:Header",
}
local function insert_header (obj, header)
	-- removes old header
	if obj[2] then
		tremove (obj, 1)
	end
	if header then
		header_template[1] = header
		tinsert (obj, 1, header_template)
	end
end

local envelope_template = {
	tag = "soap:Envelope",
	attr = { "xmlns:soap", "soap:encodingStyle", "xmlns:xsi", "xmlns:xsd",
		["xmlns:soap"] = nil, -- to be filled
		["soap:encodingStyle"] = "http://schemas.xmlsoap.org/soap/encoding/",
		["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance",
		["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema",
	},
	{
		tag = "soap:Body",
		[1] = {
			tag = nil, -- must be filled
			attr = {}, -- must be filled
		},
	}
}
local xmlns_soap = "http://schemas.xmlsoap.org/soap/envelope/"
local xmlns_soap12 = "http://www.w3.org/2003/05/soap-envelope"

---------------------------------------------------------------------
-- Converts a LuaExpat table into a SOAP message.
-- @param args Table with the arguments, which could be:
-- namespace: String with the namespace of the elements.
-- method: String with the method's name;
-- entries: Table of SOAP elements (LuaExpat's format);
-- header: Table describing the header of the SOAP envelope (optional);
-- internal_namespace: String with the optional namespace used
--	as a prefix for the method name (default = "");
-- soapversion: Number of SOAP version (default = 1.1);
-- @return String with SOAP envelope element.
---------------------------------------------------------------------
local function encode (args)
	-- if tonumber(args.soapversion) == 1.2 then
	-- 	envelope_template.attr["xmlns:soap"] = xmlns_soap12
	-- else
	-- 	envelope_template.attr["xmlns:soap"] = xmlns_soap
	-- end
	envelope_template.attr["xmlns:soap"] = xmlns_soap12
	local xmlns = "xmlns"
	if args.internal_namespace then
		xmlns = xmlns..":"..args.internal_namespace
		args.method = args.internal_namespace..":"..args.method
	end
	-- Cleans old header and insert a new one (if it exists).
	insert_header (envelope_template, args.header)
	-- Sets new body contents (and erase old content).
	local body = (envelope_template[2] and envelope_template[2][1]) or envelope_template[1][1]
	for i = 1, max (#body, #args.entries) do
		body[i] = args.entries[i]
	end
	-- Sets method (actually, the table's tag) and namespace.
	body.tag = args.method
	body.attr[xmlns] = args.namespace
	return serialize (envelope_template)
end

return {
	_COPYRIGHT = "Copyright (C) 2004-2013 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 3.0",

	decode = decode,
	encode = encode,
	escape = escape,
	unescape = unescape,
	serialize = serialize,
}
