path = require 'path'

class Style


	loader: null

	basePath: null

	section: null


	constructor: (@loader, @basePath, @section) ->


	parse: ->
		dependents = null
		if @section.style.dependencies != null
			dependents = []
			for dep in @section.style.dependencies
				dependents.push(path.resolve(@basePath + '/' + dep))

		_path = path.resolve(@basePath + '/' + @section.style.in)
		return @loader.loadFile(_path, dependents)


module.exports = Style