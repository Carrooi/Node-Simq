path = require 'path'

class Style


	loader: null

	basePath: null

	section: null


	constructor: (@loader, @basePath, @section) ->


	parse: ->
		dependents = @section.style.dependencies
		if dependents.length == 0
			dependents = null
		else
			for dep, i in dependents
				dependents[i] = path.resolve(@basePath + '/' + dep)

		_path = path.resolve(@basePath + '/' + @section.style.in)

		return @loader.loadFile(_path, dependents)


module.exports = Style