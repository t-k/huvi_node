Sequelize = require "sequelize"
config = require "./config"

db = new Sequelize(
  config.database.name
  config.database.user
  config.database.password
  {
      host: config.database.host
      port: config.database.port
      dialect: "mysql"
      pool:
        maxConnections: config.database.maxconn
        maxIdleTime: 30
      # omitNull: true
      define:
        charset: 'utf8'
        collate: 'utf8_general_ci'
  }
)
module.exports = db