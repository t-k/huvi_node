module.exports.extend = (destination, source) ->
  Object.extend = (destination, source) ->
    for property of source
      destination[property] = source[property] if source.hasOwnProperty(property)
    destination
  Object.extend destination, source

msgpack = require "msgpack"

module.exports.pack = (data) ->
  # JSON.parse
  # return msgpack.pack(data).toString('binary')
  return JSON.stringify data

module.exports.mpack = (data) ->
	return JSON.stringify data
	# return msgpack.pack(data).toString('binary')

module.exports.unpack = (data) ->
  # return msgpack.unpack(new Buffer(data.toString('binary'), 'binary'))
  return JSON.parse data

module.exports.munpack = (data) ->
	return JSON.parse data
  # return msgpack.unpack(new Buffer(data.toString('binary'), 'binary'))