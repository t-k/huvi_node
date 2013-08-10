async = require "async"
utils = require "../../lib/utils"
CONST = require "../../config/const"

generateId = ->
  generateToken = ->
    rand = new Buffer(4)
    rand.toString("base64").
      replace(/\//g, "_").
      replace(/\+/g, "-")
  time = Math.round(Date.now() / 1000)
  "#{time}:#{generateToken()}"

class SocketHandler
  constructor: (App) ->
    @App = App
    SocketManager = require "../services/socket_manager"
    @SCM = new SocketManager(
      App.Redis.Pub
      App.Redis.Sub
      App.Loggers.TdLogger
    )

  onConnection: (socket) =>
    # App = @App
    Log = @App.Loggers.TdLogger

    socket.token = generateId()
    Log.info { msg: "Client connected", socket: {id: socket.id, token: socket.token} }
    socket.emit "connected", {}

    # enter_waiting_room
    # category_id
    # as: 1 OR 5
    socket.on "enter_waiting_room", (data) =>
      if data.category_id
        Log.info { msg: "enter_waiting_room" }
        socket.as = parseInt(data.as)
        socket.category_id = parseInt(data.category_id)
        @SCM.addSockets parseInt(data.category_id), socket
    ### END enter_waiting_room ###

    # enter_room
    # ================================
    socket.on "enter_room", (data) =>
      Log.info { msg: "/room enter_room"}
      if socket.room_id
        socket.room = socket.room_id
        socket.join(socket.room)
        socket.emit "success_to_enter", {}
      else
        socket.emit "invalid", {}
    ### END enter_room ###

    # message
    # ================================
    socket.on "message", (data) =>
      Log.info { msg: "/room message"}
      if socket.room && socket.room == data.room_id && data.content
        message =
          content: data.content
        socket.emit "message_created", message
        socket.broadcast.to(socket.room).emit 'message_created', message
      else
        socket.emit "invalid", {}
    ### END message ###

    # disconnect
    # ================================
    socket.on "disconnect", =>
      Log.info { msg: "/room disconnect"}
      socket.leave(socket.room) if socket.room
      @SCM.deleteSockets socket if socket.category_id
      try
        socket.del "client"
      catch e
        Log.error { msg: "/room socket.del client", e: e }
    ### END disconnect ###

module.exports = (App) ->
  return new SocketHandler(App)