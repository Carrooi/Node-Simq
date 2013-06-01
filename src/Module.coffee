if !@require


	modules = {}

	cache = {}


	require = (name) ->
		if typeof modules[name] == 'undefined'
			throw new Error 'Module ' + name + ' was not found.'

		if typeof modules[name] == 'string'
			name = modules[name]

		if typeof cache[name] == 'undefined'
			module =
				id: name
				cached: true
				exports: {}

			modules[name].apply(window, [module.exports, (name) =>
				return @require(name)
			, module])

			if module.cached == false
				return module.exports

			cache[name] = module

		return cache[name].exports


	@require = (name) => require(name)

	@require.define = (bundle) =>
		for name, module of bundle
			modules[name] = module
		return

return @require.define