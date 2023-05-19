local typedefs = require "kong.db.schema.typedefs"

return {
  name = "log-gelf",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { uri = {type = "string"}, },
          { application_id = {required = true, type="string"}},
          { debug = {default = false, type = "boolean"} },
          { host = typedefs.host({ required = true }) },
          { port = typedefs.port({ required = true }) },
          { timeout = { type = "number", default = 10000 }, },
          { custom_fields_by_lua = typedefs.lua_code},
          { request_body_max_size_bytes = {type = "number", default=500000}},
          { response_body_max_size_bytes = {type = "number", default=500000}},

          -- Apply min and max constraints on chunk_size and chunk_max_number
          { chunk_size= {type = "number", default= 8192, between = {512, 65535} } },
          { chunk_max_number = {type = "number", default=128, between = {1, 1024} } },
          { disable_gzip_payload_decompression = {default = false, type = "boolean"}},
          { disable_capture_request_body = {default = false, type = "boolean"} },
          { capture_response_body = {default = true, type = "boolean"} },
        },
      },
    },
  },
  entity_checks = {},
}
