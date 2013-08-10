Extension = require 'easy-configuration/lib/Extension'

class DebuggerExtension extends Extension


	defaults:
		styles: false
		scripts: false
		sourceMap: false


	loadConfiguration: ->
		return @getConfig(@defaults)


module.exports = DebuggerExtension