local soap_client = require "app.libs.soap.client"
local cjson = require "cjson"
local lor = require("lor.index")
local xml2lua = require("xml2lua")
--Uses a handler that converts the XML to a Lua table
local handler = require("xmlhandler.tree")
local _M = lor:Router()

_M:get('',function(req,res,next)
    local request = {
        url = "http://Hrms.efih-foxconn.com/HrmsService/HrmsService.asmx",
        namespace = 'http://Hrms.efih-foxconn.com/HrmsService',
        method = "GetEmpInfoToACKH",
        entries = {
            { tag = "EncryptString", "8dead4b3365ecc6bbdb0cf97484403e3" },
            { tag = "employeeCode",  "F2828635" },
        }
      }
      
      local result, error_msg, extra_info = soap_client.call(request)
      if not result or error_msg or extra_info then
          return res:json{
              rv = 500,
              error_msg = error_msg,
              extra_info = extra_info
          }
      end
      return res:json{
          rv = 200,
          data = result
      }
end)

return _M