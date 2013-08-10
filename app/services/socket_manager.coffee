utils = require "../../lib/utils"

LISTPREF = "category:"
CHAN_PREFIX_ROOM = "HUVI:ROOM:"
class SocketManager
  constructor: (redis) ->
    @sockets = {}
    @Redis = redis
    @RedisPub  = redis
    @RedisSub  = redis
    # @logger  = logger
    @_chans  = {}

  addSockets: (category_id, socket) ->
    @addToRedis socket
    # @logger.info { msg: "SocketManager#addSockets: #{socket}"}
    # if @sockets[socket.category_id] == undefined
    @_subscribeRoom(socket.category_id)
    @sockets[socket.category_id] ||= {}
    @sockets[socket.category_id][socket.token] = socket
    @findUser socket

  findUser: (socket) ->
    if socket.as == 1
      as = 5
    else if socket.as == 5
      as = 1
    if as
      list = "#{LISTPREF}#{socket.category_id}:as:#{as}"
      target = @Redis.lpop list
      if target# target token
        try
          targetSock = @sockets[category_id][socket.token]
          if targetSock
            @matched user, targetSock
          else
            @findUser socket
        catch e
          @findUser socket

  matched: (user, target) ->
    if user.as == 1
      token = user.token + ":" + target.token
    else
      token = target.token + ":" + user.token
    id = @generateRoomId(user.category_id, token)
    @sendMatched(user, id)
    @sendMatched(target, id)

  sendMatched: (socket, id) ->
    msg =
      room_id: id
    socket.emit("matched", msg)

  addToRedis:  (socket) ->
    list = "#{LISTPREF}#{socket.category_id}:as:#{socket.as}"
    @Redis.lpush list, socket.token

  sendToRoom: (category_id, ev, body) ->
    sockets = @_findRoomsSockets category_id
    if sockets != undefined
      Object.keys(sockets).forEach (key) =>
        socket = @sockets[category_id][key]
        socket.emit(ev, body) if socket

  generateRoomId: (category_id, token) ->
    category_id + ":" + token

  deleteSockets: (socket) ->
    category_id = socket.category_id
    sockets = @_findRoomsSockets(category_id)
    if sockets != undefined# && sockets[client.token] != undefined
      delete @sockets[category_id][socket.token]
      if Object.keys(sockets).length == 0
        @_unsubscribeRoom socket.category_id
    else
      @_unsubscribeRoom socket.category_id
    try
      delete @sockets[category_id][socket.token]
    catch err
      # @logger.error { msg: "SocketManager#deleteSockets:", err: err }

  _findRoomsSockets: (category_id) ->
    @sockets[category_id]

module.exports = SocketManager