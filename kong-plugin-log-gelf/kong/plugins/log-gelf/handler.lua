-- Copyright (C) Linux Place fams@linuxplace.com.br

local cjson = require "cjson"
local log = require "kong.plugins.log-gelf.log"
local gelfEncoder = require "kong.plugins.log-gelf.gelfEncoder"
local kong_meta = require "kong.meta"
local sandbox = require "kong.tools.sandbox".sandbox
local kong = kong
local ngx = ngx
local timer_at = ngx.timer.at
local udp = ngx.socket.udp

local ngx_log_ERR = ngx.ERR
local ngx_log_INFO = ngx.INFO
local ngx_timer_at = ngx.timer.at
local string_format = string.format
local ngx_timer_every = ngx.timer.every

local LogGelf = {
  VERSION = "0.0.1-1",
  PRIORITY = 1100,
}


local sandbox_opts = { env = { kong = kong, ngx = ngx } }
local my_message = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
function LogGelf:log(conf)
    -- if conf.custom_fields_by_lua then
    --   local set_serialize_value = kong.log.set_serialize_value
    --   for key, expression in pairs(conf.custom_fields_by_lua) do
    --     set_serialize_value(key, sandbox(expression, sandbox_opts)())
    --   end
    -- end
    local buf = {}
    for i = 1, 300 do
        buf[#buf+1] = my_message
    end
    local final_string = table.concat( buf )
    local gelf_message = gelfEncoder:new(conf,kong.node.get_hostname(), 1)
    gelf_message:set_message("short",final_string)
    gelf_message:set_additional_fields(kong.log.serialize())
    local ok, err = timer_at(0, log.log, conf, gelf_message)
    if not ok then
      kong.log.err("could not create timer: ", err)
    end
end

return LogGelf