class Module


	modules: null


	constructor: ->
		@modules = {}


	register: (path, lib) ->
		@modules[path] = lib
		return @


	addAlias: (alias, module) ->
		if typeof @modules[module] == 'undefined'
			throw new Error 'Module ' + module + ' was not found.'

		@modules[alias] = module

		return @


	require: (path) ->
		if typeof @modules[path] == 'undefined'
			throw new Error 'Module ' + path + ' was not found.'

		if typeof @modules[path] == 'string'
			path = @modules[path]

		module =
			exports: null

		result = @modules[path].apply(@, [module])

		return if module.exports == null then result else module.exports


window._module = new Module
window.require = (path) ->
	return window._module.require(path)
