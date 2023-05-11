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
          -- { request_max_body_size_limit = {default = 100000, type = "number"} },
          -- { response_max_body_size_limit = {default = 100000, type = "number"} },
          { debug = {default = false, type = "boolean"} },
          { host = typedefs.host({ required = true }) },
          { port = typedefs.port({ required = true }) },
          { timeout = { type = "number", default = 10000 }, },
          { custom_fields_by_lua = typedefs.lua_code},
          { chunk_size= {type = "number", default= 8192}},
          { chunk_max_number = {type = "number", default=128}},
          { disable_gzip_payload_decompression = {default = false, type = "boolean"}},
          { disable_capture_request_body = {default = false, type = "boolean"} },
          { disable_capture_response_body = {default = false, type = "boolean"} },
        },
      },
    },
  },
  entity_checks = {},
}