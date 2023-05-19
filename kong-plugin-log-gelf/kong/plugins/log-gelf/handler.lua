-- Copyright (C) Linux Place fams@linuxplace.com.br

local cjson = require "cjson"
local log = require "kong.plugins.log-gelf.log"
local gelfEncoder = require "kong.plugins.log-gelf.gelfEncoder"
local kong_meta = require "kong.meta"
local sandbox = require "kong.tools.sandbox".sandbox
local timer_at = ngx.timer.at
-- local udp = ngx.socket.udp

-- local ngx_log_ERR = ngx.ERR
-- local ngx_log_INFO = ngx.INFO
-- local ngx_timer_at = ngx.timer.at
-- local string_format = string.format
-- local ngx_timer_every = ngx.timer.every

local LogGelf = {
  VERSION = "0.0.1-1",
  PRIORITY = 1100,
}


-- local sandbox_opts = { env = { kong = kong, ngx = ngx } }


function LogGelf:access(conf)
  if conf.disable_capture_request_body then
    ngx.log(ngx.DEBUG, "do not capture request body")
    return
  end
  local content_length = kong.request.get_header("Content-lenght")

  ngx.req.read_body()
  local req_body = ngx.req.get_body_data()

  -- check if the body is nil (it might be in a file)
  if not req_body then
    local req_body_file = ngx.req.get_body_file()
    if req_body_file then
      -- body is in a file, read it
      local file = io.open(req_body_file, "rb")
      req_body = file:read("*all")
      file:close()
    else
      req_body = "" -- body is empty
    end
  end

  if  (content_length == nil and string.len(req_body) <= conf.request_body_max_size_bytes) 
    or (content_length ~= nil and tonumber(content_length) <= conf.request_body_max_size_bytes) then
     if req_body then
    -- Storing the request body in kong.ctx shared context
      kong.ctx.plugin.request_body = req_body
    end
  else
    kong.ctx.plugin.request_body = ""
    kong.ctx.plugin.request_body_size_exceeded = true
  end
end

function LogGelf:body_filter(conf)
  ngx.log(ngx.DEBUG, "body_filter called ")
  local ctx = kong.ctx.plugin;
  if conf.disable_capture_response_body or ctx.stop_capture then
    ngx.log(ngx.DEBUG, "do not capture response body")
    return
  end
  local headers = ngx.resp.get_headers()
  if (headers.content_length ~= nil and tonumber(headers["content_length"]) > conf.response_body_max_size_bytes) then
    ngx.log(ngx.DEBUG, "do not capture response body. response body exceeded")
    kong.ctx.plugin.stop_capture = true
    return
  end
  local chunk, eof = ngx.arg[1], ngx.arg[2];
  local chunk_number = 0
  if not ctx.response_body then
    ngx.log(ngx.DEBUG, "Init body Capture ")
    ctx.response_body = {}
  end
  if not eof then
    ctx.response_body[#ctx.response_body+1] =  chunk or ""
    return
  end
  ngx.log(ngx.DEBUG," end body capture")
end


function LogGelf:log(conf)
  local ctx =  kong.ctx.plugin
  ngx.log(ngx.DEBUG,  ctx.response_body[0] )
  local final_string = {
    request_body = ctx.request_body,
    response_body= ctx.response_body and table.concat( ctx.response_body ) or ""
  }
  
  local gelf_message = gelfEncoder:new(conf,kong.node.get_hostname(), 1)
  gelf_message:set_message("short",final_string)
  gelf_message:set_additional_fields(kong.log.serialize())
  local ok, err = timer_at(0, log.log, conf, gelf_message)
  if not ok then
    kong.log.err("could not create timer: ", err)
  end
end

return LogGelf