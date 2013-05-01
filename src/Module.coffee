class Module


	modules: null


	constructor: ->
		@modules = {}


	register: (path, lib) ->
		@modules[path] = lib
		return @


	require: (path) ->
		if typeof @modules[path] == 'undefined'
			throw new Error 'Module ' + path + ' was not found.'

		module =
			exports: null

		result = @modules[path].apply(@, [module])

		return if module.exports == null then result else module.exports


window._module = new Module
window.require = (path) ->
	return window._module.require(path)
