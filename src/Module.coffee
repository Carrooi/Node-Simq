if !@require


	modules = {}

	nodeInfo = {}

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
		if name[0] == '.' && parent == null
			throw new Error 'Can not resolve module name ' + name

		if name[0] == '/'
			name = name.substr(1)
		else if name[0] == '.'
			num = parent.lastIndexOf('/')
			num = if num == -1 then 0 else num

			name = parent.substring(0, num) + '/' + name
		else if typeof modules[name] != 'undefined'
			# continue
		else
			count = parent.split('/').length - 1
			for i in [0..count]
				num = parent.lastIndexOf('/')
				num = if num == -1 then 0 else num

				parent = parent.substring(0, num)
				moduleName = parent + '/node_modules/' + name
				moduleName = moduleName.replace(/^\//, '')

				if typeof nodeInfo[moduleName] != 'undefined' && nodeInfo[moduleName].name == name
					name = nodeInfo[moduleName].path
					break

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


	@require._setNodeInfo = (data) ->
		nodeInfo = data
		return


return @require.define