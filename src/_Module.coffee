if !@require


	SUPPORTED = ['js', 'json', 'ts', 'coffee']

	modules = {}

	cache = {}


	require: (name, parent = null) ->
		fullName = resolve(name, parent)
		if fullName == null
			throw new Error 'Module ' + name + ' was not found.'

		if typeof cache[fullName] == 'undefined'
			m =
				exports: {}
				id: fullName
				filename: fullName
				loaded: false
				parent: null
				children: null

			modules[fullName].apply(modules[fullName], [m.exports, (fullName, parent = null) =>
				return @require(fullName, parent)
			, m])

			m.loaded = false

			cache[fullName] = m

		return cache[fullName].exports


	resolve: (name, parent = null) ->
		if typeof modules[name] != 'undefined'
			return name

		if parent != null && name[0] != '/'
			name = parent + '/' + name
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

			name = result.join('/')

			if typeof modules[name] != 'undefined'
				return name

		for ext in SUPPORTED
			return name + '.' + ext if typeof modules[name + '.' + ext] != 'undefined'

		for ext in SUPPORTED
			return name + '/index.' + ext if typeof modules[name + '/index.' + ext] != 'undefined'

		return null


	@require = (name, parent = null) ->
		return require(name, parent)


	@require.resolve = (name, parent = null) ->
		return resolve(name, parent)


	@require.define = (bundle) ->
		for name, m of bundle
			modules[name] = m


	@require.cache = cache


return @require.define