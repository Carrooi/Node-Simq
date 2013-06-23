Extension = require 'easy-configuration/lib/Extension'

class DebuggerExtension extends Extension


	defaults:
		styles: null
		scripts: null
		sourceMap: false

	debug: false


	constructor: (@debug) ->


	loadConfiguration: ->
		config = @getConfig(@defaults)

		if config.styles == null then config.styles = @debug
		if config.scripts == null then config.scripts = @debug

		return config


module.exports = DebuggerExtension