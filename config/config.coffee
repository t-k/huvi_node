path = require "path"
fs = require "fs"

process.env.NODE_ENV ||= "development"
console.log "NODE_ENV:", process.env.NODE_ENV
filepath = path.join(__dirname, "./json/env.json")
configJSON = fs.readFileSync(filepath)
config = JSON.parse(configJSON.toString())[process.env.NODE_ENV]

module.exports = config