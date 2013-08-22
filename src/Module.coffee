if !@require


	modules = {}

	meta= {}

	cache = {}


	require = (name, parent = null) ->
		name = resolve(name, parent)

		if typeof modules[name] == 'undefined'
			throw new Error 'Module ' + name + ' was not found.'

		if typeof modules[name] == 'string'
			name = resolve(modules[name])

		if typeof cache[name] == 'undefined'
			module =
				exports: {}
				id: name
				filename: name
				loaded: false
				parent: null
				children: null

			modules[name].apply(modules[name], [module.exports, (name, parent = null) =>
				return @require(name, parent)
			, module])

			module.loaded = false

			cache[name] = module

		return cache[name].exports


	resolve = (name, parent = null) ->
		if name[0] == '.' && parent == null
			throw new Error 'Can not resolve module name ' + name

		checkName = (name) ->
			if typeof modules[name] != 'undefined'
				return name
			else if typeof modules[name + '.js'] != 'undefined'
				return name + '.js'
			else if typeof modules[name + '.json'] != 'undefined'
				return name + '.json'
			else if typeof modules[name + '.coffee'] != 'undefined'
				return name + '.coffee'
			else if typeof modules[name + '.ts'] != 'undefined'
				return name + '.ts'
			else if typeof modules[name + '.eco'] != 'undefined'
				return name + '.eco'
			else
				return name

		if name[0] == '/'
			name = name.replace(/^\/*/, '')
		else if name[0] == '.'
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

		name = result.join('/')

		name = checkName(name)

		if typeof modules[name] == 'undefined'
			if typeof meta[name] != 'undefined'
				name = checkName(meta[name].path)
			else
				num = name.indexOf('/')
				base = name.substring(0, num)
				rest = name.substr(num + 1)

				if typeof meta[base] != 'undefined'
					name = checkName("#{meta[base].base}/#{rest}")

		return name


	@require = (name, parent = null) ->
		return require(name, parent)


	@require.define = (bundle) ->
		for name, module of bundle
			modules[name] = module
		return


	@require.resolve = (name, parent = null) ->
		return resolve(name, parent)


	@require.cache = cache


	@require._setMeta = (data) ->
		meta = data
		return


return @require.define