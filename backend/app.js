
module.exports = require('./deps.js').then(async ({
  server,
  helper,
  configs,
  db,
  ql
}) => {
  await configs.checkup()
  await configs.setup()

  return {
    server: await server.startServer(helper, configs)
  }
}).catch(console.log)
