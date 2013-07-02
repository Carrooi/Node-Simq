if !@require


	modules = {}

	cache = {}


	require = (name, parent = null) ->
		name = resolve(name, parent)

		if typeof modules[name] == 'undefined'
			throw new Error 'Module ' + name + ' was not found.'

		if typeof modules[name] == 'string'
			name = resolve(modules[name])

		if typeof cache[name] == 'undefined'
			module =
				id: name
				cached: true
				exports: {}

			modules[name].apply(modules[name], [module.exports, (name, parent = null) =>
				return @require(name, parent)
			, module])

			if module.cached == false
				return module.exports

			cache[name] = module

		return cache[name].exports


	resolve = (name, parent = null) ->
		if name[0] == '.' && parent != null
			num = parent.lastIndexOf('/')
			num = if num == -1 then 0 else num

			name = parent.substring(0, num) + '/' + name

		parts = name.split('/')

		result = []
		prev = null

		for part in parts
			if part == '.' || part == ''
				continue
			else if part == '..' && prev
				result.pop()
			else
				result.push(part)

			prev = part

		return result.join('/')


	@require = (name, parent = null) ->
		return require(name, parent)


	@require.define = (bundle) ->
		for name, module of bundle
			modules[name] = module
		return


return @require.define