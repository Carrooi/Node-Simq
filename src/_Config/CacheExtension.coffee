Extension = require 'easy-configuration/lib/Extension'

class CacheExtension extends Extension


	defaults:
		directory: null


	loadConfiguration: ->
		return @getConfig(@defaults)


module.exports = CacheExtension