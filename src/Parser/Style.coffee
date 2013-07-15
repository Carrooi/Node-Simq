_path = require 'path'
less = require 'less'
fs = require 'fs'
Q = require 'q'

class Style


	loader: null


	constructor: (@loader) ->


	parse: (path, packageName) ->
		return @loader.loadFile(_path.resolve(path), packageName)


module.exports = Style