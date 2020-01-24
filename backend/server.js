const http = require('http')
const util = require('util')
const events = require('events')
const fs = require('fs')
const stream = require('stream')
const zlib = require('zlib')
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

  cache: {
    map: new Map,

    has: route_url =>
      server.cache.map.has(route_url),

    store: (full_filepath, options) => {
      let filestream = fs.createReadStream(full_filepath)
      let compressstream = null
      let compression = ''

      switch(options && options.compression) {
        case 'brotli':
          compression = options.compression
          compressstream = zlib.createBrotliCompress({
            params: {
              [zlib.constants.BROTLI_PARAM_MODE]: zlib.constants.BROTLI_MODE_TEXT,
              [zlib.constants.BROTLI_PARAM_QUALITY]: zlib.constants.BROTLI_MAX_QUALITY,
              [zlib.constants.BROTLI_PARAM_SIZE_HINT]: fs.statSync(full_filepath).size
            }
          })
          break;

        case 'gzip':
          compression = options.compression
          compressstream = zlib.createGzip({
            level: zlib.constants.Z_BEST_COMPRESSION
          })
      }

      if(compressstream) filestream = filestream.pipe(compressstream)

      let b = Buffer.from('')

      const onData = c =>
        b = Buffer.concat([b, c])

      const onEnd = () => {
        filestream.removeListener('data', onData)
        server.cache.map.set(compression + ':' + full_filepath, {b, options})
      }

      filestream.on('data', onData)
      filestream.once('end', onEnd)
    },

    get: (route_url, req, res) => {
      let compression = req.supportsBrotli()
        ? 'brotli'
        : req.supportsGzip()
        ? 'gzip'
        : ''

      const {b, options} = server.cache.map.get(compression + ':' + route_url)
      const pt = new stream.PassThrough
      pt.push(b)
      pt.push(null)
      pt.__ignore_compression = true
      pt.__cached = true

      if(options && options.compression === 'brotli')
        res.brotli.setup()
      else if(options && options.compression === 'gzip')
        res.gzip.setup()

      return pt
    }
  },

  time: {
    waitRandom: () =>
      new Promise(r => setTimeout(r, 600 + Math.random() * 400))
  }
})


