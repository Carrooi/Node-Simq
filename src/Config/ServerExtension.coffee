Extension = require 'easy-configuration/lib/Extension'

class ServerExtension extends Extension


	defaults:
		port: 3000


	loadConfiguration: ->
		return @getConfig(@defaults)


module.exports = ServerExtension