var gelfserver = require('graygelf/server')
var server = gelfserver()
console.log("Ready to receive messages")
server.on('message', function (gelf) {
  // handle parsed gelf json
  console.log('received short message:', gelf.short_message)
  console.log('received full message:', gelf.full_message)
})
process.on('SIGINT', () => {
  console.info("Interrupted");
  process.exit(0);
})

server.listen(12201)