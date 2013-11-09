Extension = require 'easy-configuration/lib/Extension'

class DebuggerExtension extends Extension


	defaults:
		minify: true
		filesStats: true


	loadConfiguration: ->
		return @getConfig(@defaults)


module.exports = DebuggerExtension