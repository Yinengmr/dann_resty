local soap_client = require "app.libs.soap.client"
local cjson = require "cjson"
local xml2lua = require("xml2lua")
--Uses a handler that converts the XML to a Lua table
local handler = require("xmlhandler.tree")


local request = {
  url = "http://hr.efih-foxconn.com/AttendService/AttendService.asmx",
  namespace = 'http://tempuri.org/',
  method = "GetACKHGetCRInfo",
  entries = {
      { tag = "PwdString", "1w!EM^xkk*D9^qdZ1li4At*JAIGX$%b@xneu3I3zUl0ySPWE1G" },
      { tag = "start_time",  "2018-09-07 00:50:00" },
      { tag = "end_time",    "2018-09-07 00:55:00" },
  }
}

local result, error_msg, extra_info = soap_client.call(request)


print(cjson.encode(result)) 

print('-------------------------------------------------------------------------------------------')

local request = {
  url = "http://hr.efih-foxconn.com/AttendService/AttendService.asmx",
  namespace = 'http://tempuri.org/',
  method = "GetACKHGetCRInfo",
  entries = {
      { tag = "PwdString", "1w!EM^xkk*D9^qdZ1li4At*JAIGX$%b@xneu3I3zUl0ySPWE1G" },
      { tag = "start_time",  "2018-09-07 00:55:00" },
      { tag = "end_time",    "2018-09-07 01:00:00" },
  }
}


local result, error_msg, extra_info = soap_client.call(request)


print(cjson.encode(result)) 