path = require "path"
fs = require "fs"

filepath = path.join(__dirname, "./json/const.json")
configJSON = fs.readFileSync(filepath)
CONST = JSON.parse(configJSON.toString())

module.exports = CONST