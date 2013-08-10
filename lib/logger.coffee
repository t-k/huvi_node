config = require "../config/config"
logger = require "./fluent-logger"
util = require "util"

LOG_LEVEL =
  debug:  3
  info:   2
  warn:   1
  error:  0
  fatal: -1

class Logger
  constructor: (tag = "vlchat", options = {}) ->
    console.log "td-logger", "initializing..."
    console.log "td-logger", "host:", options.host
    console.log "td-logger", "port:", options.port
    console.log "td-logger", "tag:", tag
    console.log "td-logger", "log level:", options.level
    @debugMode = options.debug || true
    @tag       = tag
    @host      = options.host
    @port      = options.port
    @level     = options.level
    @_logger   = new logger(
      host: @host
      port: @port
    )
    # @log = @

  debug: (message) ->
    @_log "debug", message

  info: (message) ->
    @_log "info", message

  warn: (message) ->
    @_log "warn", message

  error: (message) ->
    @_log "error", message

  fatal: (message) ->
    @_log "fatal", message

  close: ->
    @_logger.close()

  _log: (label, message) ->
    console.log(message) if @debugMode == true
    if LOG_LEVEL[label] <= @level
      @_logger.post "#{@tag}.#{label}", message

opt =
  host:  config.td.host
  port:  config.td.port
  debug: config.td.debug
  level: LOG_LEVEL[config.td.log_level]

tdLogger = new Logger(config.td.tag, opt)

module.exports = tdLogger