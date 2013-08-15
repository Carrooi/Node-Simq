path = require 'path'

class Style


	loader: null

	section: null


	constructor: (@loader, @section) ->


	parse: ->
		return @loader.loadFile(@section.style.in, @section.style.dependencies)


module.exports = Style