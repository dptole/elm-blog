const querystring = require('querystring')
const util = require('util')
const events = require('events')
const ql = new events



module.exports = helper => 
util._extend(ql, {
  OR: '&|&',

  OP_GT: '>>',
  OP_NEQ: '!',
  OP_IN: '[]',

  TYPE_INT: 'i:',
  TYPE_NULL: 'n:',
  TYPE_DATE: 'd:',

  type: {
    null: () => ql.TYPE_NULL
  },

  convert: {
    toInt: value => ql.TYPE_INT + value,
    toDate: value => ql.TYPE_DATE + value
  },

  operator: {
    GT: field => field + ql.OP_GT,
    NEQ: field => field + ql.OP_NEQ,
    IN: field => field + ql.OP_IN
  },

  init: qls => {
    const OR = ql.OR

    const operators = [
      {
        symbol: '[]!',
        test: (ctx_value, search_value) =>
          Array.isArray(ctx_value) &&
          !ctx_value.includes(search_value)
      },
      {
        symbol: ql.OP_GT,
        test: (ctx_value, search_value) => ctx_value > search_value
      },
      {
        symbol: '<<',
        test: (ctx_value, search_value) => ctx_value < search_value
      },
      {
        symbol: ql.OP_IN,
        test: (ctx_value, search_value) =>
          Array.isArray(ctx_value) &&
          ctx_value.includes(search_value)
      },
      {
        symbol: '>',
        test: (ctx_value, search_value) => ctx_value >= search_value
      },
      {
        symbol: '<',
        test: (ctx_value, search_value) => ctx_value <= search_value
      },
      {
        symbol: ql.OP_NEQ,
        test: (ctx_value, search_value) => ctx_value !== search_value
      }
    ]

    const conversions = [
      {
        symbol: ql.TYPE_DATE,
        parse: v => new Date(v)
      },
      {
        symbol: ql.TYPE_INT,
        parse: v => parseInt(v)
      },
      {
        symbol: ql.TYPE_NULL,
        parse: () => null
      }
    ]

    const parseQls = () =>
      (helper.is.string(qls) ? qls : '').split(OR).reduce((acc, qs) => {
        const q = {...querystring.parse(qs)}
        return acc.concat(Object.keys(q).length > 0 ? q : [])
      }, [])

    const convertValue = value => {
      value = helper.is.string(value) ? value : ''
      const convs = []

      while(1) {
        let found = false

        for(const co of conversions) {
          const v = value.slice(0, co.symbol.length)

          if(v === co.symbol) {
            convs.push(co.parse)
            value = value.slice(v.length)
            found = true
          }
        }

        if(!found) break
      }

      return convs.reduce((value, conv) => conv(value), value)
    }

    const getPropertyOperator = property_name => {
      property_name = helper.is.string(property_name) ? property_name : ''

      for(const op of operators) {
        const pn = property_name.slice(-op.symbol.length)

        if(pn === op.symbol)
          return op.test
      }

      return (search_value, ctx_value) => search_value === ctx_value
    }

    const getPropertyName = property_name => {
      let pn = property_name

      while(1) {
        let found = false

        for(const co of conversions) {
          const symbol = pn.slice(0, co.symbol.length)

          if(symbol === co.symbol) {
            pn = pn.slice(symbol.length)
            found = true
          }
        }

        if(!found) break
      }

      for(const op of operators) {
        const symbol = pn.slice(-op.symbol.length)

        if(symbol === op.symbol) {
          pn = pn.slice(0, -symbol.length)
          break
        }
      }

      return pn
    }

    const parseProperty = (properties, property_name) => {
      properties = helper.is.object(properties)
        ? {...properties}
        : {}

      property_name = helper.is.string(property_name)
        ? property_name
        : ''

      const value = convertValue(properties[property_name])
      const name = getPropertyName(property_name)
      const operator = getPropertyOperator(property_name)
      
      return {
        value,
        name,
        operator
      }
    }

    const match = ctx => {
      if(or.length < 1)
        return true

      ctx = helper.is.object(ctx) ? {...ctx} : {}

      return or.some(and => {
        const props = Object.keys(and)

        if(props.length < 1)
          return false

        return props.every(prop => {
          const p = parseProperty(and, prop)

          const ctx_value = helper.accessField(ctx, p.name)

          const qs_value = p.value &&
            helper.is.func(p.value.valueOf)
            ? p.value.valueOf()
            : p.value

          return p.operator(
            ctx_value,
            qs_value
          )
        })
      })
    }

    const getQls = () => qls

    const or = parseQls()

    return {match,getQls}
  },

  createBasicQuery: (...queries) =>
    ql.init(
      queries.map(query => querystring.stringify(query)).join(ql.OR)
    )
})
