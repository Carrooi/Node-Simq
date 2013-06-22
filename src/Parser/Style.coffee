_path = require 'path'
less = require 'less'
fs = require 'fs'
Q = require 'q'

class Style


	loader: null

	basePath: null


	constructor: (@loader) ->


	parse: (path) ->
		return @loader.loadFile(_path.resolve(path))


module.exports = Style