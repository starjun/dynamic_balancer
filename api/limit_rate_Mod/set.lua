-- 动态域名 修改

-- id = "" 修改完整规则组信息
-- id = %num% 修改指定 id 对应的完整规则

local stool = require "stool"
local optl  = require "optl"
local modcache = require("modcache")

local config_dict = ngx.shared["config_dict"]
local dict_key_name = "config"
local tb_key_name = "limit_rate_Mod"
local config = stool.stringTojson(config_dict:get(dict_key_name))
if not config then
    optl.sayHtml_ext({ code = "error", msg = "config_dict:config is error" })
end

local _id = optl.get_paramByName("id")
local _value = optl.get_paramByName("value")
-- {
--     "state": "on",
--     "limit_rate":"100k",
--     "id":"www.test.com limit_rate 100k",
--     "hostname": ["www.test.com",""],
--     "uri":[["down","static"],"rein_list"]
-- }


_value = stool.stringTojson(_value)
if type(_value) ~= "table" then
    -- value 转 json 失败
    optl.sayHtml_ext({code="error",msg="value Tojson error"})
else
    if _id == "" then
        -- 替换整个规则
        if stool.isArrayTable(_value) then
            config[tb_key_name] = _value
            local re = config_dict:replace(dict_key_name , stool.tableTojsonStr(config))
            if not re then
                optl.sayHtml_ext({ code = "error", msg = "error in set while replacing" })
            end
            -- 更新 dict version 标记
            modcache.dict_tag_up(dict_key_name)
            optl.sayHtml_ext({ code = "ok", msg = "set rules success" })
        end
    else
        _id = tonumber(_id)
        if not _id then
            optl.sayHtml_ext({ code = "ok", msg = "id is error" })
        end
        if not config[tb_key_name][_id] then
            optl.sayHtml_ext({ code = "ok", msg = "id is Non-existent" })
        else
            config[tb_key_name][_id] = _value
            local re = config_dict:replace(dict_key_name , stool.tableTojsonStr(config))
            if not re then
                optl.sayHtml_ext({ code = "error", msg = "error in set while replacing" })
            end
            -- 更新 dict version 标记
            modcache.dict_tag_up(dict_key_name)
            optl.sayHtml_ext({ code = "ok", msg = "set rules success" })
        end
    end
end