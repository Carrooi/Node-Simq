path = require 'path'

class Style


	loader: null


	constructor: (@loader) ->


	parse: (_path, packageName) ->
		return @loader.loadFile(path.resolve(_path), packageName)


module.exports = Style