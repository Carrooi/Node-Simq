if !@require


	SUPPORTED = ['js', 'json', 'ts', 'coffee', 'eco']

	modules = {}

	stats = {}

	cache = {}


	require = (name, parent = null) ->
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

			modules[fullName].apply(modules[fullName], [m.exports, m])

			m.loaded = true

			cache[fullName] = m

		if typeof stats[fullName] == 'undefined' then stats[fullName] = {atime: null, mtime: null, ctime: null}
		stats[fullName].atime = new Date

		return cache[fullName].exports


	resolve = (name, parent = null) ->
		if parent != null && name[0] == '.'

			# get directory path
			num = parent.lastIndexOf('/')
			if num != -1 then parent = parent.substr(0, num)

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
			name = '/' + name if parent[0] == '/'

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


	@require.release = ->
		for name of cache
			delete cache[name]


	@require.getStats = (name, parent = null) ->
		fullName = resolve(name, parent)
		if fullName == null
			throw new Error 'Module ' + name + ' was not found.'

		if typeof stats[fullName] == 'undefined' then stats[fullName] = {atime: null, mtime: null, ctime: null}
		return stats[fullName]


	@require.__setStats = (bundle) ->
		for name, data of bundle
			stats[name] =
				atime: new Date(data.atime)
				mtime: new Date(data.mtime)
				ctime: new Date(data.ctime)


	@require.cache = cache


return @require.define