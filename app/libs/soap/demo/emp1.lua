local soap_client = require "app.libs.soap.client"
local cjson = require "cjson"

local xml2lua = require("xml2lua")
--Uses a handler that converts the XML to a Lua table
local handler = require("xmlhandler.tree")


local request = {
    url = "http://hrms.efih-foxconn.com/HrWebSerices/HrmsService.asmx",
    namespace = 'http://Hrms.efih-foxconn.com/HrmsService',
    method = "ACKHGetEmpInfo",
    entries = {
        { tag = "PwdString", "1w!EM^xkk*D9^qdZ1li4At*JAIGX$%b@xneu3I3zUl0ySPWE1G" }
    }
  }
  
  local result, error_msg, extra_info = soap_client.call(request)
  
  
  print(cjson.encode(result)) 