local cjson = require "cjson"
local socket = require "socket"

local GELF_VERSION = "1.1"

local GELF_MAGICK = string.char(0x1e) .. string.char( 0x0f)

local _M = {}

local function get_id()
    local buf = {}
    local timestamp_mili = socket.gettime()*1000
    ngx.log(ngx.DEBUG, "timestamp_mili:" .. timestamp_mili)
    for i = 1, 8 do
        buf[#buf+1] = string.format('%x', math.random(0, 0xf))
    end
    return table.concat(buf)
end

function _M:new(conf, host, level)
    self.msg = {}
    self.conf = conf
    self.chunk_data_size = conf.chunk_size-12
    self.msg.version = GELF_VERSION
    self.msg.host = host
    self.msg.level = level
    self.parsed = nil
    self.id = get_id()
    return self
end

function _M:set_message(short_message, full_message)
    self.msg.short_message = short_message
    self.msg.full_message = full_message
    self.parsed = nil
end

function _M:set_additional_fields(fields)
    if #fields > 1 then
        for k,v in pairs(fields) do
            self.msg["_".. k] = v
        end
    end
    self.parsed = nil
end

function _M:chunk(count)
    if not self.parsed then
        self.parsed = cjson.encode(self.msg)
    end
    
    --[[
    chunkSize        int
    chunkDataSize    int
    compressionType  int
    compressionLevel int
    --]]
    
    if #self.parsed < self.chunk_data_size  then
        return 0, self.parsed
    end
    ngx.log(ngx.DEBUG,"Sending chunk: " .. count)

    local total = math.ceil(#self.parsed / self.chunk_data_size)
    if total > self.conf.chunk_max_number then error("Message chunks exceeded") end
    ngx.log(ngx.DEBUG, "Total: " .. total .. " = math.ceil(" .. #self.parsed .. " / " .. self.chunk_data_size .. ")")
    
    local next_chunk = count + 1
    ngx.log(ngx.DEBUG, "Next chunk" .. next_chunk)
    return  (total - next_chunk ) == 0 and 0 or next_chunk,
        GELF_MAGICK .. self.id .. string.char(count) .. string.char(total) 
            .. string.sub(
                self.parsed,
                count*self.chunk_data_size,
                (count+1)*self.chunk_data_size
            )
end

return _M