
module.exports = (async d =>
  Object.keys(d = {
    db: ['helper', 'server', 'ql'],

    helper: ['db', 'routes', 'configs', 'server', 'ql'],

    routes: ['helper', 'db', 'server', 'ql'],

    configs: ['helper'],

    ql: ['helper'],

    server: ['helper', 'configs']
  }).reduce((deps, dep) =>
    (
      require('util')._extend(
        deps[dep] || (deps[dep] = {}),
        require(`${__dirname}/${dep}.js`)(
          ...d[dep].map(node =>
            deps[node] || (deps[node] = {})
          )
        )
      ),
      deps
    ),
    {}
  )
)()
