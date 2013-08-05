Extension = require 'easy-configuration/lib/Extension'

class RoutesExtension extends Extension


	defaults:
		prefix: null
		main: './public/index.html'
		routes: {}


	loadConfiguration: ->
		return @getConfig(@defaults)


module.exports = RoutesExtension