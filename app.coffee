App =
  Models:   {}
  Services: {}
  Loggers:  {}
  Redis:    {}
  Caches:   {}

## td-agent Logger
App.Loggers.TdLogger = require "./lib/logger"

# load ./config/json/env.json
Config = require "./config/config"
# load ./config/json/const.json
CONST = require "./config/const"

socketIO = require "socket.io"

## To use name prefix, override socket.io manager.js generateId
NAME_PREFIX = CONST["SOCKET_IO"]["NAME_PREFIX"]
crypto = require "crypto"
socketIO.Manager::generateId = ->
  rand = new Buffer(15)
  if !rand.writeInt32BE
    return Math.abs(Math.random() * Math.random() * Date.now() | 0).toString() + Math.abs(Math.random() * Math.random() * Date.now() | 0).toString()
  this.sequenceNumber = (this.sequenceNumber + 1) | 0
  rand.writeInt32BE(this.sequenceNumber, 11)
  if crypto.randomBytes
    crypto.randomBytes(12).copy(rand)
  else
    [0, 4, 8].forEach( (i) ->
      rand.writeInt32BE(Math.random() * Math.pow(2, 32) | 0, i)
    )
  return NAME_PREFIX + rand.toString('base64').replace(/\//g, '_').replace(/\+/g, '-')

DEFAULT_PORT = Config.server.port || 8080
port = process.argv[2] || DEFAULT_PORT
io = socketIO.listen port
App.Loggers.TdLogger.info { msg: "server listens on port #{port}" }

## For production
io.configure "production", ->
  io.set "log level", 2

## For labo2
io.configure "staging", ->
  io.set "log level", 3

## For test
io.configure "test", ->
  io.set "log level", 3

## For development
io.configure "development", ->
  io.set "log level", 3

## Redis store
redis = require "redis"
RedisStore = require "socket.io/lib/stores/redis"
redisOpts =
  host: Config.redis.host
  port: Config.redis.port
console.log "redisOpts:", redisOpts
redisPub    = redis.createClient(redisOpts.port, redisOpts.host, redisOpts)
redisSub    = redis.createClient(redisOpts.port, redisOpts.host, redisOpts)
redisClient = redis.createClient(redisOpts.port, redisOpts.host, redisOpts)

## Socket.io config
utils = require "./lib/utils"
# msgpack = require "msgpack"

Static = require('socket.io').Static

io.configure ->
  io.enable "browser client minification"
  io.enable "browser client etag"
  io.enable "browser client gzip"
  _static = new Static(io)
  io.static.add "/socket.io.min.js",
    mime:
      type: "application/javascript"
      encoding: "utf8"
      gzip: true

    file: "#{Config.app_root}/public/socket.io.min.js"

  io.static.add "/WebSocketMain.swf",
    mime:
      type: "application/x-shockwave-flash"

    file: "#{Config.app_root}/public/WebSocketMain.swf"

  io.static.add "/WebSocketMainInsecure.swf",
    mime:
      type: "application/x-shockwave-flash"

    file: "#{Config.app_root}/public/WebSocketMainInsecure.swf"

  io.set 'public', _static
  io.set "logger", App.Loggers.TdLogger
  io.set "transports", [
    "websocket"
    "flashsocket"
    "jsonp-polling"
    "xhr-polling"
    "htmlfile"
  ]
  io.set "browser client", true
  io.set "browser client cache", true
  io.set "polling duration", 15
  io.set "connect timeout", 500
  io.set "reconnect", true
  io.set 'close timeout', 500
  io.set "heartbeat interval", 20
  io.set "heartbeat timeout", 60
  io.set "store", new RedisStore(
    redis:       redis
    redisPub:    redisPub
    redisSub:    redisSub
    redisClient: redisClient
    pack: (data) ->
      return utils.mpack(data)
    unpack: (data) ->
      return utils.munpack(data)
  )

## Redis
App.Redis.Pub = redisPub
App.Redis.Sub = redisSub

## Socket connection handler
chatHandler = require("./app/sockets/socket_handler")(App)
io.of("/chat").on "connection", socketHandler.onConnection

## Graceful shutdown
process.on 'SIGTERM', ->
  App.Loggers.TdLogger.info { msg: "shutting down" }
  App.Loggers.TdLogger.close()
  App.Redis.Pub.close()
  App.Redis.Sub.close()
  redisPub.quit()
  redisSub.quit()
  redisClient.quit()