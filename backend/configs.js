const util = require('util')
const events = require('events')
const configs = new events



module.exports = helper =>
util._extend(configs, {
  PORT: 9090,
  REQUEST_MAX_PAYLOAD_BYTES: 1024 * 1024, // 1 MB
  MIN_RESPONSE_BYTES_TO_COMPRESS: 1024, // 1 KB
  MAX_REQUESTS_PER_MINUTE: 50,

  setup: async () => {
    // Date

    Date.convertLabelToMs = (label, amount = 1) => {
      if(label === 'millisecond')
        return amount

      if(label === 'second')
        return amount *= 1000

      if(label === 'minute')
        return amount *= 1000 * 60

      if(label === 'hour')
        return amount *= 1000 * 60 * 60

      if(label === 'day')
        return amount *= 1000 * 60 * 60 * 24

      if(label === 'week')
        return amount *= 1000 * 60 * 60 * 24 * 7

      throw new Error(`Unknown label: "${label}"`)
    }

    Date.prototype.add = function(amount, label) {
      this.setTime(this.getTime() + Date.convertLabelToMs(label, amount))
      return this
    }

    Date.prototype.copy = function() {
      return new Date(+this)
    }

    Date.prototype.isValid = function() {
      return Number.isFinite(+this)
    }

    // Error

    Error.prototype.toJSON = function() {
      return {
        message: this.message,
        name: this.name,
        stack: this.stack
      }
    }

    // Object

    Object.prototype.listValues = function(separator, ending) {
      const k = Object.values(this)
      if(separator === 0[0] && ending === 0[0])
        return k
      if(k.length < 2)
        return k[0]
      return k.slice(0, -1).join(separator) + ending + k.last()
    }

    Object.prototype.field = function(field_names, fallback) {
      if(!Array.isArray(field_names) || field_names.length < 1)
        return fallback

      let that = this

      for(let i = 0; i < field_names.length; i++) {
        try {
          if(field_names[i] in that)
            that = that[field_names[i]]
          else
            return fallback
        } catch(_) {
          return fallback
        }
      }

      return that
    }

    // Array

    Array.prototype.first = function(fallback) {
      fallback = helper.is.string(fallback) ? fallback : null
      return this.length > 0 ? this[0] : fallback
    }

    Array.prototype.last = function(fallback) {
      return this.slice(-1).first(fallback)
    }

    Array.prototype.has = function(item) {
      return !!~this.indexOf(item)
    }

    Array.prototype.isLast = function(item) {
      return this.length === 1 + this.indexOf(item)
    }
  },

  checkup: async () => {
    console.log('Performing a Nodejs checkup...')
    await helper.checkup.nodejs()
    console.log('OK')

    console.log('Performing a DB checkup...')
    await helper.checkup.db()
    console.log('OK')
  }
})
