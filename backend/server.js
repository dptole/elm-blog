const http = require('http')
const util = require('util')
const events = require('events')
const server = new events



module.exports = (helper, {PORT}) =>
util._extend(server, {
  startServer: () => new Promise((resolve, reject) => {
    const http_server = http.createServer(async (req, res) => {
      try {
        await helper.request.setup(req, res)
        await req.__route(req, res)
      } catch(e) {
        console.log('Error setting up/routing request', e)

        res.__error = e

        if(server.errorObject.template.isValid(e))
          res.jsonTemplate(e)
        else
          helper.routes.default.internalServerError(req, res)
      }
    })

    http_server.once('error', error => {
      helper.warn('http_server.once("error")', error)
      http_server.close()
      reject(error)
    })

    http_server.on('clientError', (error, socket) => {
      helper.warn('http_server.on("clientError")', error)
      socket.destroy()
    })

    http_server.on('connection', socket => {
      helper.socket.setTimeout(socket, () => {
        socket.destroy()
      })
    })

    http_server.listen(PORT, () => {
      console.log('HTTP server ready on port ' + PORT)
      resolve(http_server)
    })
  }),

  errorObject: {
    template: {
      DEFAULT_OUTPUT: 'json',
      DEFAULT_STATUS: 500,
      DEFAULT_EXTRA: null,

      create: () => ({
        status: server.errorObject.template.DEFAULT_STATUS,
        errors: [],
        extra: server.errorObject.template.DEFAULT_EXTRA,
        output: server.errorObject.template.DEFAULT_OUTPUT
      }),

      isValid: template =>
        template &&
        'extra' in template &&
        'output' in template &&
        Number.isInteger(template.status) &&
        template.status > 99 &&
        template.status < 600 &&
        Array.isArray(template.errors) &&
        Object.keys(template).length === 4
    },

    create: () => {
      const eb = server.errorObject.template.create()

      const self = {
        status: status => (eb.status = status, self),
        addError: error => (eb.errors.push({_: error}), self),
        extra: extra => (eb.extra = extra, self),
        output: output => (eb.output = output, self),
        addFieldError: (field, error) => (eb.errors.push({[field]: error}), self),
        has: () => eb.errors.length > 0,
        throw: () => {throw eb}
      }

      return self
    }
  },

  time: {
    waitRandom: () =>
      new Promise(r => setTimeout(r, 600 + Math.random() * 400))
  }
})


