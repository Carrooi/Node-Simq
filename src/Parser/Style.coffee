path = require 'path'

class Style


	loader: null


	constructor: (@loader) ->


	parse: (_path, pckg) ->
		dependents = if pckg.style.dependencies.length == 0 then null else pckg.style.dependencies
		return @loader.loadFile(path.resolve(_path), dependents)


module.exports = Style