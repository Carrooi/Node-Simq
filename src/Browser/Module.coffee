if !@require


	SUPPORTED = ['js', 'json', 'ts', 'coffee', 'eco']

	modules = {}

	stats = {}

	cache = {}

	creating = []


	require = (name, parent = null) ->
		fullName = resolve(name, parent)

		if typeof cache[fullName] == 'undefined'
			m =
				exports: {}
				id: fullName
				filename: fullName
				loaded: false
				parent: null
				children: null

			# circular reference detection
			if arrayIndexOf(creating, fullName) == -1
				creating.push(fullName)
				modules[fullName].apply(window, [m.exports, m])
				creating.splice(arrayIndexOf(creating, fullName))

				cache[fullName] = m

			m.loaded = true
		else
			m = cache[fullName]

		if typeof stats[fullName] == 'undefined' then stats[fullName] = {atime: null, mtime: null, ctime: null}
		stats[fullName].atime = new Date

		return m.exports


	resolve = (name, parent = null) ->
		original = name

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
		if (original[0] == '/') || (parent != null && parent[0] == '/' && original[0] == '.')
			name = '/' + name

		if typeof modules[name] != 'undefined'
			return name

		for ext in SUPPORTED
			return name + '.' + ext if typeof modules[name + '.' + ext] != 'undefined'

		for ext in SUPPORTED
			return name + '/index.' + ext if typeof modules[name + '/index.' + ext] != 'undefined'

		throw new Error "Module #{original} was not found."


	arrayIndexOf = (array, search) ->
		if typeof Array.prototype.indexOf != 'undefined'
			return array.indexOf(search)

		if array.length == 0
			return -1

		for element, i in array
			if element == search
				return i

		return -1


	@require = (name, parent = null) ->
		return require(name, parent)


	@require.simq = true


	@require.version = 1


	@require.resolve = (name, parent = null) ->
		return resolve(name, parent)


	@require.define = (bundleOrName, obj = null) ->
		if typeof bundleOrName == 'string'
			modules[bundleOrName] = obj
		else
			for name, m of bundleOrName
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