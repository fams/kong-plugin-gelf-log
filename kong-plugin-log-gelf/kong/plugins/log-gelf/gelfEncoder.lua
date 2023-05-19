local cjson = require "cjson"   -- Import the cjson module for JSON encoding/decoding
-- local socket = require "socket" -- Import the socket module for time functions
local ffi = require "ffi"

-- local bit = require "bit"


local GELF_VERSION = "1.1" -- Constant for the GELF version

local GELF_MAGICK = string.char(0x1e) .. string.char(0x0f) -- Constant for the GELF magic string

local _M = {} -- Module table to hold functions and data


-- Define the C data types for uint64_t and uint8_t
ffi.cdef[[
    typedef uint64_t uint64_t;
    typedef uint8_t uint8_t;
]]


function get_id()
    -- Generate a random 64-bit unsigned integer
    local id = ffi.cast("uint64_t", math.random(0, 0xFFFFFFFFFFFFFFFF))
  
    -- Convert the integer to an 8-byte string
    local id_str = ffi.string(ffi.cast("uint8_t*", ffi.new("uint64_t[1]", id)), 8)
  
    return id_str
end

function _M:new(conf, host, level)
    self.msg = {} -- Create a table to hold the log message
    self.conf = conf -- Store the provided configuration
    self.chunk_data_size = conf.chunk_size - 12 -- Calculate the chunk data size based on the configuration
    self.msg.version = GELF_VERSION -- Set the GELF version in the log message
    self.msg.host = host -- Set the host in the log message
    self.msg.level = level -- Set the log level in the log message
    self.parsed = nil -- Initialize the parsed JSON string to nil
    self.id = get_id() -- Generate an ID for the log message
    return self -- Return the initialized object
end

function _M:set_message(short_message, full_message)
    self.msg.short_message = short_message -- Set the short log message
    self.msg.full_message = full_message -- Set the full log message
    self.parsed = nil -- Reset the parsed JSON string
end

function _M:set_additional_fields(fields)
    if #fields > 1 then -- Check if additional fields are provided
        for k, v in pairs(fields) do
            self.msg["_" .. k] = v -- Add each additional field to the log message, prefixed with an underscore
        end
    end
    self.parsed = nil -- Reset the parsed JSON string
end

function _M:chunk(count)
    if not self.parsed then
        self.parsed =  cjson.encode(self.msg) -- Encode the log message table into a JSON string if not already done
    end


    if #self.parsed < self.chunk_data_size then
        return 0, self.parsed -- Return a single chunk with count 0 if the message size is smaller than the chunk data size
    end

    ngx.log(ngx.DEBUG, "Sending chunk: " .. count) -- Log the chunk count being sent

    local total = math.ceil(#self.parsed / self.chunk_data_size) -- Calculate the total number of chunks required
    if total > self.conf.chunk_max_number then
        error("Message chunks exceeded") -- Check if the total number of chunks exceeds the configured maximum and raise an error if so
    end
    ngx.log(ngx.DEBUG, "Total: " .. total .. "= math.ceil(" .. #self.parsed .. " / " .. self.chunk_data_size .. ")") -- Log the total number of chunks being calculated

    local next_chunk = count + 1 -- Calculate the index of the next chunk
    ngx.log(ngx.DEBUG, "Next chunk" .. next_chunk) -- Log the index of the next chunk
    
    -- Construct the chunk payload by appending the GELF magic string, ID, count, total, and a substring of the JSON string based on the chunk index
    return (total - next_chunk) == 0 and 0 or next_chunk,
        GELF_MAGICK .. self.id .. string.char(count) .. string.char(total) ..
        string.sub(
            self.parsed,
            count * self.chunk_data_size,
            (count + 1) * self.chunk_data_size
        )
end

return _M -- Return the module table as the final result