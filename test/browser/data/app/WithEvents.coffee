EventEmitter = require('events').EventEmitter

class WithEvents extends EventEmitter


	callMe: -> @emit('call', 'hello')


module.exports = WithEvents