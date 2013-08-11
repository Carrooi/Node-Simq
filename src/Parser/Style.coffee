path = require 'path'

class Style


	loader: null

	section: null


	constructor: (@loader, @section) ->


	parse: ->
		dependents = @section.style.dependencies
		if dependents.length == 0
			dependents = null

		return @loader.loadFile(path.resolve(@section.style.in), dependents)


module.exports = Style