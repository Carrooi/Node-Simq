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
		else
			if parent == null then parent = ''
			count = parent.split('/').length - 1

			num = name.indexOf('/')
			if num == -1
				nameRest = null
			else
				nameRest = name.substr(num + 1)
				name = name.substr(0, num)

			for i in [0..count]
				num = parent.lastIndexOf('/')
				num = if num == -1 then 0 else num

				parent = parent.substring(0, num)
				moduleName = parent + '/node_modules/' + name
				moduleName = moduleName.replace(/^\//, '')

				if typeof nodeInfo[moduleName] != 'undefined' && nodeInfo[moduleName].name == name
					if nameRest == null
						name = nodeInfo[moduleName].path
					else
						name = moduleName + '/' + nameRest

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


		name = result.join('/')

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

		return checkName(name)


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