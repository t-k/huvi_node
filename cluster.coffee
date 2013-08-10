cluster = require "cluster"
numCPUs = require('os').cpus().length
size = if numCPUs >= 2 then numCPUs else 2

console.log "setup #{size} forks"

if cluster.isMaster
  i = 0
  while i < size
    cluster.fork()
    i++
  cluster.on "exit", (worker) ->
    console.log "worker #{worker.process.pid} disconnected."
else
  require "./app"