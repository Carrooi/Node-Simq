class Module


	modules: null

	cache: null


	constructor: ->
		@modules = {}
		@cache = {}


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

		if typeof @cache[path] == 'undefined'
			module =
				exports: {}

			@modules[path].apply(window, [module])

			@cache[path] = module

		return @cache[path].exports



window._module = new Module
window.require = (path) ->
	return window._module.require(path)
