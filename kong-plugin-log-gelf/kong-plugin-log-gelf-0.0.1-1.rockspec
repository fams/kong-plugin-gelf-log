package = "kong-plugin-log-gelf"
version = "0.0.1-1"
source = {
  url = "git://github.com/fams/kong-plugin-log-gelf",
  branch = "master"
}
description = {
  summary = "This plugin allows Kong to send logs with body to a udp gelf server"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.log-gelf.handler"] = "kong/plugins/log-gelf/handler.lua",
    ["kong.plugins.log-gelf.gelfEncoder"] = "kong/plugins/log-gelf/gelfEncoder.lua",
    ["kong.plugins.log-gelf.schema"]  = "kong/plugins/log-gelf/schema.lua",
    ["kong.plugins.log-gelf.log"]  = "kong/plugins/log-gelf/log.lua",
  }
}