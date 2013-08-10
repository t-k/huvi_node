msgpack = require "msgpack"
net = require "net"
EventEmitter = require("events").EventEmitter

class FluentLogger
  constructor: (options = {}) ->
    @host         = options.host || "127.0.0.1"
    @port         = options.port || 24224
    @timeout      = options.timeout || 3.0
    @bufferLimit  = options.bufferLimit || 8 * 1024 * 1024
    @retryWait    = options.retryWait || 500
    @maxRetry     = options.maxRetry || 13
    @retryCount   = 0
    @pending      = new Buffer("")
    @socket       = null
    @eventEmitter = new EventEmitter()

  post: (tag, message) ->
    data = @_toMsgPack tag, message
    if data != null
      if @pending.length > 0
        @pending = Buffer.concat([@pending, new Buffer(data)])
      else
        @pending = data
      @send()

  send: ->
    try
      @_send()
    catch e
      @_flushBuffer() if @pending.length > @bufferLimit

  close: ->
    @send() if @pending.length > 0
    @_close()

  _toMsgPack: (tag, message) ->
    timeNow = @_getTime()
    msg = [tag, timeNow, message]
    try
      return msgpack.pack(msg)
    catch e
      console.error "FluentLogger: Can't convert to msgpack: #{message}"
      return null

  _getTime: ->
    return (new Date().getTime()) / 1000

  _send: ->
    unless @_isConnected()
      @_connect()
    if @socket != null
      @socket.write @pending, =>
        @_flushBuffer()

  _connect: (cb) ->
    @socket = new net.Socket()
    @socket.setTimeout @timeout
    @socket.on "error", (error) =>
      if @retryCount > @maxRetry
        @eventEmitter.emit("error", error)
      else
        console.error("FluentLogger: an error occurred", error)
        @retryCount += 1
        @_close()
    @socket.connect @port, @host, =>
      @retryCount = 0
      cb() if cb
    @socket.on "close", =>
      @close()

  _close: ->
    if @_isConnected
      @socket.end() if @socket
      @socket = null

  _isConnected: ->
    @socket != null# && @socket.writable

  _flushBuffer: ->
    @pending = new Buffer("")

module.exports = FluentLogger