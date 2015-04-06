###
Copyright (c) 2014, Groupon
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.###

http = require "http"
express = require "express"
morgan = require "morgan"
bodyParser = require "body-parser"
methodOverride = require "method-override"
config = require "./config"
api = require("./routes/api")
routes = require "./routes/routes"
socketIO = require "socket.io"

app = express()
app.use cors()
server = http.createServer app
sockets = socketIO(server)

#app.use morgan('dev')
app.use bodyParser.urlencoded
  extended: true
app.use bodyParser.json()
app.use methodOverride()
app.use express.static("#{__dirname}/../../public")

api(app, sockets)
routes(app)

port = process.env.PORT || config.server?.port || 4994
server.listen port
console.log "GScreen is listening to localhost:#{port}"
ip = require "ip"

bootTV = (host) ->
  client = clients[host].client
  client.connect clients[host].addr, ->
    client.heartbeat.on 'timeout', ->
      console.log 'TO %s', host
      return
    console.log '%s connected, loading Gscreen', clients[host].addr
    client.receiver.send
      type: 'LAUNCH'
      appId: 'AE17EB79'
      requestId: 1
    return
  client.on 'error', (err) ->
    console.log 'Error: %s, %s', err.message, host
    if client != undefined
      client.close()
    clients[host].client = new Client
    bootTV host
    return
  return

Client = require('castv2-client').Client
DefaultMediaReceiver = require('castv2-client').DefaultMediaReceiver
mdns = require('mdns')
browser = mdns.createBrowser(mdns.tcp('googlecast'))
bootGS = false
clients = {}
console.log 'Started first mdns query'
browser.on 'serviceUp', (service) ->
  host = service.addresses[0]
  console.log 'found device "%s" at %s:%d', service.name, host, service.port
  clients[host] = {}
  clients[host].addr = service.addresses[0]
  clients[host].client = new Client
  bootTV host
  browser.stop()
  return
browser.start()
