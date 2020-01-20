const url = require('url')
const fs = require('fs')
const path = require('path')
const http = require('http')
const os = require('os')
const zlib = require('zlib')
const querystring = require('querystring')
const util = require('util')
const dns = require('dns')
const events = require('events')
const helper = new events



module.exports = (db, routes, configs, server, ql) =>
util._extend(helper, {
  CONS: {
    ACCESS_FIELD: {
      SPLITTER: '.'
    }
  },

  checkup: {
    db: db.checkup,

    nodejs: async () => {
      if(parseFloat(process.versions) < 11.15)
        throw new Error('Nodejs v11.15+ required')
    }
  },

  cookies: {
    auth_token: 'auth-token'
  },

  errors: {
    extractMessagesFromResponse: (default_messages, res) => {
      if(helper.is.string(default_messages))
        default_messages = [{_: default_messages}]

      if(!Array.isArray(default_messages))
        default_messages = [default_messages]

      let error_messages = res.__error

      if(error_messages instanceof Error)
        error_messages = [res.__error.message]

      if(!Array.isArray(error_messages))
        error_messages = [error_messages]

      const errors = error_messages.reduce((acc, e) => {
        if(!(e instanceof Error))
          return acc

        acc.push(e.message)

        return acc
      }, [])

      const default_errors = default_messages.reduce((acc, e) => {
        if('string' !== typeof e)
          return acc

        acc.push(e)

        return acc
      }, [])

      if(errors.length > 0)
        return errors

      if(default_messages.length > 0)
        return default_messages

      return ['Unexpected error handling.']
    },

    generateResponse : (req, res, default_messages) => {
      const error_messages = helper.errors.extractMessagesFromResponse(
        default_messages,
        res
      )

      const json_error = {
        errors: error_messages,
        reqid: req.__reqid
      }

      helper.request.log(req, res, json_error)

      return json_error
    }
  },

  socket: {
    setTimeout: (socket, timeout) => {
      if(socket.__timeout)
        return false

      socket.setTimeout(60e3, socket.__timeout = timeout)

      return true
    }
  },

  response: {
    status: (req, res, status_code) => {
      res.statusCode = status_code
      return helper.response.output
    },

    header: {
      json: res => {
        const JSON_HEADER = 'application/json'
        const HEADER = 'content-type'

        if(res.getHeader(HEADER) === JSON_HEADER)
          return false

        res.setHeader(HEADER, JSON_HEADER)

        return true
      }
    },

    output: {
      json: (req, res, data) => {
        helper.response.header.json(res)

        if(helper.is.object(data))
          data.meta = {
            status_code: res.statusCode,
            headers: res.getHeaders()
          }

        helper.request.log(req, res, data)

        const string_data = helper.json.stringify(data)
        let output_function = 'end'

        if(string_data.length > configs.MIN_RESPONSE_BYTES_TO_COMPRESS)
          output_function = req.supportsBrotli()
            ? 'brotli'
            : req.supportsGzip()
            ? 'gzip'
            : 'end'

        res[output_function](string_data)
      },

      empty: (req, res) => {
        helper.request.log(req, res)
        res.end()
      }
    }
  },

  request: {
    log: (req, res, response_payload) => {
      res.once('finish', () => {
        helper.log('REMOTE ADDRESS', req.socket.remoteAddress)
        helper.log('CONNECTION ID', req.__conid)
        helper.log('REQUEST ID', req.__reqid)
        helper.log('REQUEST METHOD', req.method)
        helper.log('REQUEST URL', req.url)
        helper.log('REQUEST ROUTE', req.__route && req.__route.path)
        helper.log('REQUEST PARAMS', req.__params)
        helper.log('REQUEST HEADER', helper.inspect(req.headers))

        helper[req.url.includes('/avatar') ? 'log2' : 'log']('REQUEST PAYLOAD', req.__buffer.toString())

        helper.log('RESPONSE STATUS CODE', res.statusCode)
        helper.log('RESPONSE STATUS MESSAGE', res.statusMessage)
        helper.log('RESPONSE HEADER', helper.inspect(res.getHeaders()))

        if(res.statusCode < 200 || res.statusCode > 399)
          helper.log('RESPONSE ERROR', res.__error)

        helper[req.url.includes('/avatar') ? 'log2' : 'log']('RESPONSE PAYLOAD', helper.inspect(response_payload))

        helper.log('='.repeat(70))
      })
    },

    injectHelpers: (req, res) => {
      // Socket
      req.__socket = helper.server.sockets.create(req)
      req.__socket.reqs.push(Date.now())

      // Request & Response
      res.cookies = req.cookies = helper.cookies
      res.__req = req
      req.__res = res

      // Request
      req.__route = helper.routes.getRouteHandler(req)
      req.__buffer = Buffer.from('')
      req.__qs = querystring.parse(req.__url.query)
      req.__reqid = helper.request.createRequestId(req)
      req.__conid = helper.request.createConnectionId(req)

      req.payloadDecoders = db.payloadDecoders
      req.qsDecoders = db.qsDecoders
      req.paramsDecoders = db.paramsDecoders

      req.decodePayload = async decoder =>
        await helper.decoders.json(
          req,
          decoder
        )

      req.decodeQs = async decoder =>
        await helper.decoders.qs(
          req,
          decoder
        )

      req.decodeParams = async decoder =>
        await helper.decoders.params(
          req,
          decoder
        )

      req.initQl = q => ql.init(q)

      req.getParsedQs = () => {
        const qs = req.getQs()
        const parsed_qs = {}

        for(const n in qs) {
          let parsed = qs[n]

          if(helper.is.string(parsed))
            parsed = [parsed]

          if(!helper.is.arrayOfStrings(parsed))
            parsed = []

          parsed_qs[n] = parsed
        }

        return parsed_qs
      }

      req.getQs = () => {
        try {
          return {...req.__qs}
        } catch(error) {
          res.error(error)
            .errors
            .INTERNAL_SERVER_ERROR
            .throw(500)
        }
      }

      req.authenticate = async () => {
        const auth_token = req.getCookie(req.cookies.auth_token, 0)

        if(!auth_token)
          res.errors.INVALID_TOKEN.throw(401)

        let token = null
        try {
          token = await db.tokens.get(auth_token)
        } catch(error) {
          res.expireCookie(req.cookies.auth_token)
            .error(error)
            .errors
            .INVALID_TOKEN
            .throw(401)
        }

        if(token.expires < new Date().toJSON()) {
          res.expireCookie(req.cookies.auth_token)
            .errors
            .INVALID_TOKEN_EXPIRED
            .throw(401)
        }

        return req.__route.path === '/me'
          ? token
          : await db.tokens.extendExpirationDate(token)
      }

      req.supportsEncoding = name =>
        'string' === typeof req.headers['accept-encoding'] &&
        req.headers['accept-encoding'].split(/ *, */).includes(name)

      req.supportsGzip = () =>
        req.supportsEncoding('gzip')

      req.supportsBrotli = () =>
        req.supportsEncoding('br')

      req.getCookie = (name, select_index = 0) => {
        const cookies = req.headers.cookie
        if(!cookies) return null

        const cookies_object = cookies.split(/ *; */).reduce((acc, cookie) => {
          const kv = cookie.split('=')

          if(!acc[kv[0]])
            acc[kv[0]] = []

          acc[kv[0]].push(kv[1])

          return acc
        }, {})

        const cookie_values = name in cookies_object ? cookies_object[name] : []

        if(Number.isFinite(select_index))
          return cookie_values[select_index] 

        return cookie_values
      }

      // Response

      res.errors = db.errors

      res.gzip = data =>
        res.gzip.createCompress().end(data).pipe(
          (
            res.gzip.setup(),
            res
          )
        )

      res.gzip.setup = () =>
        res.setHeader('content-encoding', 'gzip')

      res.gzip.createCompress = () =>
        zlib.createGzip({
          level: zlib.constants.Z_BEST_COMPRESSION
        })

      res.brotli = data =>
        res.brotli.createCompress(data.length).end(data).pipe(
          (
            res.brotli.setup(),
            res
          )
        )

      res.brotli.setup = () =>
        res.setHeader('content-encoding', 'br')

      res.brotli.createCompress = size_hint =>
        zlib.createBrotliCompress({
          params: {
            [zlib.constants.BROTLI_PARAM_MODE]: zlib.constants.BROTLI_MODE_TEXT,
            [zlib.constants.BROTLI_PARAM_QUALITY]: zlib.constants.BROTLI_MAX_QUALITY,
            [zlib.constants.BROTLI_PARAM_SIZE_HINT]: size_hint
          }
        })

      res.header = (header_name, header_value) => {
        if(header_value === undefined && helper.is.string(header_name))
          return res.getHeader(header_name)

        if(helper.is.object(header_name))
          for(const header_key of Object.keys(header_name))
            res.setHeader(header_key, header_name[header_key])

        else
          res.setHeader(header_name, header_value)

        return res
      }

      res.file = (filepath, autopipe = true, autocache = true) => {
        const root_path = __dirname
        const full_filepath = path.resolve(root_path, 'public/dist', filepath)

        if(!full_filepath.startsWith(root_path))
          return res.status(403).end()

        const filestream = autocache && server.cache.has(full_filepath)
          ? server.cache.get(full_filepath, req, res)
          : fs.createReadStream(full_filepath)

        if(!filestream.__ignore_compression) {
          if(req.supportsBrotli()) {
            server.cache.store(full_filepath, {compression: 'brotli'})

            return filestream.pipe(
              res.brotli.createCompress(
                fs.statSync(full_filepath).size
              )
            ).pipe(
              (res.brotli.setup(), res)
            )
          }

          if(req.supportsGzip()) {
            server.cache.store(full_filepath, {compression: 'gzip'})

            return filestream.pipe(
              res.gzip.createCompress()
            ).pipe(
              (res.gzip.setup(), res)
            )
          }
        }

        if(!filestream.__cached)
          server.cache.store(full_filepath)

        return filestream.pipe(res)
      }

      res.empty = () => {
        helper.response.output.empty(req, res)
        return res
      }

      res.todo = () =>
        res.status(501).json({
          todo: 'Not yet implemented.'
        })

      res.json = object => {
        helper.response.output.json(
          req, res, object
        )
        return res
      }

      res.status = status_code => {
        res.statusCode = status_code
        return res
      }

      res.getCookiesAsArray = () => res.getHeader('set-cookie') || []

      res.getCookies = () => {
        const cookies = res.getCookiesAsArray()

        return cookies.map(cookie =>
          // cookie = 'name=value;path=/;httpOnly'
          cookie.split(';')
        ).reduce((acc, splitted_cookie) => {
          // splitted_cookie = [ 'name=value', 'path=/', 'httpOnly' ]

          const sub_acc = splitted_cookie.reduce((acc, splitted_cookie_item, index) => {
            // splitted_cookie_item = 'name=value'
            const key_value = splitted_cookie_item.split('=')

            if(index)
              acc[key_value[0]] = key_value.length > 1 ? key_value[1] : true
            else
              acc.name = key_value

            return acc
          }, {})

          if(!acc[sub_acc.name[0]])
            acc[sub_acc.name[0]] = {
              [sub_acc.path]: sub_acc
            }

          acc[sub_acc.name[0]][sub_acc.path] = sub_acc

          return acc
        }, {})
      }

      res.setCookie = (name, value, path, expires, http_only = true) => {
        const cookies = res.getCookies()

        if(cookies[name] && cookies[name][path])
          return res

        const cookies_list = res.getCookiesAsArray()
        res.setHeader('set-cookie', [
          ...cookies_list,
          [
            name + '=' + value,
            'path=' + path,
            'expires=' + expires.toGMTString(),
            http_only && 'httpOnly'
          ].join(';')
        ])

        return res
      }

      res.expireCookie = (name, path = '/', http_only = true) => {
        res.setHeader('set-cookie', [
          ...res.getCookiesAsArray(),
          [
            name + '=',
            'path=' + path,
            'max-age=0',
            http_only && 'httpOnly'
          ].join(';')
        ])

        return res
      }

      res.jsonTemplate = template => {
        res.__error = template.extra
        return res.status(template.status)[
          template.output
        ]({
          reqid: req.__reqid,
          errors: template.errors
        })
      }

      res.error = error => {
        res.__error = error
        return res
      }
    },

    checkSecurity: (req, res) => {
      if(helper.is.string(req.url) && req.url.length > 1e3)
        res.errors
          .REQUEST_URL_TOO_LONG
          .throw(414)

      const one_min_ago = Date.now() - 60 * 1e3
      const socket = req.__socket

      if(socket.reqs.length > configs.MAX_REQUESTS_PER_MINUTE) {
        if(socket.reqs[0] > one_min_ago) {
          socket.reqs.shift()
          res.errors
            .TOO_MANY_REQUESTS
            .throw(429)
        }
      }

      req.__socket.reqs = req.__socket.reqs.filter(req_ms => req_ms > one_min_ago)
    },
  
    setup: async (req, res) => {
      //await server.time.waitRandom()

      helper.request.injectHelpers(req, res)
      helper.request.checkSecurity(req, res)

      res.setHeader('access-control-allow-credentials', 'true')

      res.setHeader(
        'access-control-allow-origin',
        req.headers['origin'] || '*'
      )

      if(req.headers['access-control-request-headers'])
        res.setHeader(
          'access-control-allow-headers',
          req.headers['access-control-request-headers']
        )

      if(req.headers['access-control-request-method'])
        res.setHeader(
          'access-control-allow-methods',
          req.headers['access-control-request-method']
        )
    },

    createRequestId: req =>
      req.__reqid || (req.__reqid = helper.random.dateAndMath()),

    createConnectionId: req =>
      req.socket.__conid || (req.socket.__conid = helper.random.dateAndMath()),

    readRequestPayload: req => {
      return new Promise((resolve, reject) => {
        if(!(req instanceof http.IncomingMessage)) {
          reject(
            new Error(
              'The request must be an instance of http.IncomingMessage.'
            )
          )
          return;
        }

        if(req.__buffer.length > 0) {
          resolve(req.__buffer)
          return;
        }

        const offData = () =>
          req.removeListener('data', onData)

        const offEnd = () =>
          req.removeListener('end', onEnd)

        const onData = chunk => {
          if(req.__buffer.length >= configs.REQUEST_MAX_PAYLOAD_BYTES) {
            offData()
            offEnd()
            helper.routes.default.payloadTooLarge(req, req.__res)
            
          } else
            req.__buffer = Buffer.concat([
              req.__buffer,
              chunk
            ])
        }

        const onEnd = () => {
          offData()
          resolve(req.__buffer)
        }

        req.on('data', onData)
        req.once('end', onEnd)
      })
    }
  },

  random: {
    dateAndMath: () =>
      Date.now().toString(16) + Math.random().toString(36).substr(2)
  },

  url: {
    parse: request_url => {
      try {
        return url.parse(request_url)
      } catch(error) {
        return null
      }
    }
  },

  decoders: {
    json: (req, dataDecoder) => {
      if(!helper.is.func(dataDecoder))
        server.errorObject
          .create()
          .status(500)
          .addError(db.errors.INVALID_JSON_DECODER.string())
          .throw()

      return helper.request.readRequestPayload(req).then(buffer =>
        JSON.parse(buffer.toString())
      ).catch(e =>
        server.errorObject
          .create()
          .extra(e)
          .status(400)
          .addError(db.errors.INVALID_JSON_PAYLOAD.string())
          .throw()
      ).then(dataDecoder)
    },

    qs: (req, dataDecoder) =>
      dataDecoder(req.__qs),

    params: (req, dataDecoder) =>
      dataDecoder(req.__params)
  },

  routes: {
    getRouteHandler: req => {
      req.__url = helper.url.parse(req.url)
      req.__params = {}

      const method_routes = helper.routes.methods[req.method]

      const maybeNotFound = async (req, res) => {
        if(req.method === 'HEAD' || req.method === 'OPTIONS')
          res.end()
        else
          helper.routes.default.notFound(req, res)
      }

      if(!helper.is.object(method_routes))
        return maybeNotFound

      const request_url = req.__url.pathname.split('/')

      label:for(const path in method_routes) {
        req.__params = {}
        const route_url = path.split('/')

        for(let i = 0; i < request_url.length; i++) {
          if(!(
            route_url[i] !== 0[0] &&
            request_url[i] !== 0[0]
          ))
            continue label

          if(route_url[i][0] === '*') {
            req.__params['*'] = request_url.slice(i).join('/')
            break
          }

          if(route_url[i][0] === ':') {
            req.__params[route_url[i].substr(1)] = request_url[i]
            continue
          }

          if(route_url[i] !== request_url[i])
            continue label
        }

        if(helper.is.func(method_routes[path])) {
          const route = method_routes[path].bind()
          route.path = path
          return route
        }
      }

      return maybeNotFound
    },

    default: {
      notFound: (req, res) => {
        res.status(404).json(
          helper.errors.generateResponse(req, res, 'Route not found.')
        )
      },

      badRequest: (req, res) => {
        res.status(400).json(
          helper.errors.generateResponse(req, res, 'Bad request.')
        )
      },

      payloadTooLarge: (req, res) => {
        res.status(413).json(
          helper.errors.generateResponse(req, res, 'Payload too large.')
        )
        res.socket.destroy()
      },

      internalServerError: (req, res) => {
        res.status(500).json(
          helper.errors.generateResponse(req, res, 'Internal server error.')
        )
      }
    },

    methods: routes
  },

  warn: (title, ...args) =>
    helper.log('!' + title, ...args),

  inspect: (...args) =>
    util.inspect(...args, {depth: 14}),

  log: (...args) => {
    console.log(...args)
    db.log(
      [
        new Date().toJSON(),
        ...args
      ].map(helper.json.tryStringifyNonString).join(' ')
    )
  },

  log2: (...args) => {
    db.log(
      [
        new Date().toJSON(),
        ...args
      ].map(helper.json.tryStringifyNonString).join(' ')
    )
  },

  json: {
    tryParse: string => {
      try {
        return JSON.parse(string)
      } catch(error) {}
    },

    tryStringifyNonString: data => {
      try {
        if('string' === typeof data) return data

        return JSON.stringify(data, 0, 2)
      } catch(error) {}
      return ''
    },

    stringify: data => {
      try {
        return JSON.stringify(data, 0, 2) + os.EOL
      } catch(error) {
        throw error
      }
    }
  },

  is: {
    func: f =>
      'function' === typeof f,

    string: s =>
      'string' === typeof s || s instanceof String,

    nonEmptyString: s =>
      helper.is.string(s) &&
      s.trim().length > 0,

    object: o =>
      o !== null &&
      'object' === typeof o &&
      (
        o.constructor === 0[0] ||
        o.constructor === Object
      ),

    validUrl: async u => {
      const parsed_url = url.parse(u)

      if(!(
        helper.is.string(parsed_url.host) &&
        helper.is.string(parsed_url.protocol) &&
        helper.regex.httpProtocol.test(parsed_url.protocol)
      ))
        return false

      try {
        const d = await dns.promises.lookup(parsed_url.hostname)
        return d && d.family === 4 && d.address !== '127.0.0.1'
      } catch(error) {
        helper.warn(
          'validUrl',
          'Error performing a DNS lookup',
          parsed_url,
          error
        )
        return false
      }
    },

    arrayOfStrings: array_of_strings =>
      Array.isArray(array_of_strings) &&
      array_of_strings.every(string => helper.is.string(string)),

    id: id =>
      helper.is.nonEmptyString(id) &&
      /^[a-z0-9]+$/.test(id),

    dateObject: d =>
      d instanceof Date
  },

  regex: {
    digits: /\d+/,
    iAlpha: /^[.0-9a-z-_]+$/i,
    iText: /^[ ,'"?!%&@[\]{}().0-9a-z-_#$*+\/\\\n\r]+$/i,
    httpProtocol: /^https?:$/i
  },

  shouldBe: {
    array: (array, fallback = []) =>
      Array.isArray(array) ? array : fallback,

    arrayOfString: (array, fallback = []) =>
      Array.isArray(array) ? array.filter(string => helper.shouldBe.string(string)): fallback,

    string: (string, fallback = '') =>
      helper.is.string(string) ? string : fallback,

    object: (object, fallback = {}) =>
      helper.is.object(object) ? object : fallback,

    tcpPort: (port, fallback) =>
      Number.isFinite(port) &&
      (port | 0) === port &&
      port >= 0 &&
      port <= 65535
        ? port
        : fallback,

    number: (number, fallback = 0) =>
      Number.isFinite(number) ? number : fallback
  },

  identity: v => v,

  accessField: (obj, field_name, fallback, splitter = helper.CONS.ACCESS_FIELD.SPLITTER) =>
    obj && helper.is.func(obj.field)
      ? obj.field(helper.shouldBe.string(field_name).split(splitter), fallback)
      : fallback,

  server: {
    sockets: {
      map: new Map,

      create: req => {
        const {address, family, port} = req.socket.address()
        const socket_id = address + '/' + family + '/' + port
        const socket = helper.server.sockets.map.get(socket_id)

        if(socket) return socket

        helper.server.sockets.map.set(socket_id, {reqs: []})
        return helper.server.sockets.map.get(socket_id)
      }
    }
  }
})
