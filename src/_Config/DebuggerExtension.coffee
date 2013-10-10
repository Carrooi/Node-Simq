Extension = require 'easy-configuration/lib/Extension'

class DebuggerExtension extends Extension


	defaults:
		styles: false
		scripts: false
		sourceMap: false
		sourceMaps: false


	loadConfiguration: ->
		config = @getConfig(@defaults)

		if config.sourceMap == true && config.sourceMaps == false
			config.sourceMaps = config.sourceMap

		delete config.sourceMap

		return config


module.exports = DebuggerExtension