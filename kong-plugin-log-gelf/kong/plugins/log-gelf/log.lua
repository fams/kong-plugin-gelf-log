

local kong_meta = require "kong.meta"


local ngx = ngx
local timer_at = ngx.timer.at
local udp = ngx.socket.udp



local _M = {}

-- local function getChunks(conf, str)
--   local chunks ={
--     gziped = false,
--     chunks = 0
--   }
--   if len(str)> conf.chunkThreashould then
    
--   end
--   return chunks
-- end


function _M.log(premature, conf, gm)
  if premature then
    return
  end

  local sock = udp()
  sock:settimeout(conf.timeout)

  local ok, err = sock:setpeername(conf.host, conf.port)
  if not ok then
    kong.log.err("could not connect to ", conf.host, ":", conf.port, ": ", err)
    return
  end
  local count = 0
  local buf = ""
  repeat 
    count, buf = gm:chunk(count)
    ok, err = sock:send(buf)
    if not ok then
      kong.log.err("could not send data to ", conf.host, ":", conf.port, ": ", err)

    else
      kong.log.debug("sent (", count, ") :", string.sub(buf,0,100), "...")
    end
  until count < 1
  ok, err = sock:close()
  if not ok then
    kong.log.err("could not close ", conf.host, ":", conf.port, ": ", err)
  end
end

return _M