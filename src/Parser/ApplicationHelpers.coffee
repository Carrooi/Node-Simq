required = require 'required'
Q = require 'q'
fs = require 'fs'
path = require 'path'
Finder = require 'fs-finder'

class ApplicationHelpers


	@findDependentModules: (from) ->
		if path.extname(from) != '.js'
			result =
				files: [from]
				core: []
				node: {}
			if (info = @findPackageInfo(from)) != null
				result.node[info.dir] =
					name: info.name
					main: info.main

			return Q.resolve(result)

		parse = (dep) ->
			result =
				files: []
				core: []

			if dep.core == true
				result.core.push(dep.id)
			else
				result.files.push(dep.filename)
				if dep.deps.length > 0
					for sub in dep.deps
						ext =
							parse(sub)
						result.files = result.files.concat(ext.files)
						result.core = result.core.concat(ext.core)

			return result

		deferred = Q.defer()
		required(from, ignoreMissing: true, (e, deps) =>
			if e
				deferred.reject(e)
			else
				res =
					files: [from]
					core: []
					node: {}

				for dep in deps
					ext = parse(dep)
					res.files = res.files.concat(ext.files)
					res.core = res.core.concat(ext.core)

				for file in res.files
					if (info = @findPackageInfo(file)) != null
						res.files.push(info.main)
						res.node[info.dir] =
							name: info.name
							main: info.main

				#res.files = res.files.filter( (item, index) -> return res.files.indexOf(item) != index )
				#res.core = res.core.filter( (item, index) -> return res.core.indexOf(item) != index )

				deferred.resolve(res)
		)
		return deferred.promise


	@isInModule: (file) ->
		return file.lastIndexOf('/node_modules/') != -1


	@getModuleName: (file) ->
		buf = file.substr(file.lastIndexOf('/node_modules/') + 14)
		return buf.substr(0, buf.indexOf('/'))


	@getModuleBaseDir: (file) ->
		return file.substr(0, file.lastIndexOf('/node_modules/') + 14) + @getModuleName(file)


	@getModuleInfo: (file, pckg) ->
		main = if typeof pckg.main == 'undefined' then './index' else pckg.main
		dir = @getModuleBaseDir(file)
		main = dir + '/' + main
		main = @resolveNodeFile(main)

		result =
			file: file
			name: @getModuleName(file)
			main: path.normalize(main)
			dir: dir

		return result


	@resolveNodeFile: (_path) ->
		_path = path.resolve(_path)
		if fs.existsSync(_path)
			if fs.statSync(_path).isDirectory()
				return @findNodeFile(_path + '/index')
			else
				return _path
		else if fs.existsSync(_path + '.js')
			return _path + '.js'
		else if fs.existsSync(_path + '.json')
			return _path + '.json'
		else if fs.existsSync(_path + '.coffee')
			return _path + '.coffee'
		else if fs.existsSync(_path + '.ts')
			return _path + '.ts'
		else if fs.existsSync(_path + '.eco')
			return _path + '.eco'
		else
			return null


	@findNodePackage: (file) ->
		if @isInModule(file)
			return @getModuleBaseDir(file) + '/package.json'

		return null


	@findPackageInfo: (file) ->
		pckg = @findNodePackage(file)
		if pckg == null
			return null
		else
			pckg = JSON.parse(fs.readFileSync(pckg, encoding: 'utf8'))
			return @getModuleInfo(file, pckg)


	@parseModulesList: (list, basePath) ->
		modules = []
		for module in list
			module = path.resolve(basePath + '/' + module)
			if fs.existsSync(module)
				modules.push(module)
			else
				modules = modules.concat(Finder.findFiles(module))

		return modules


	@findDependentModulesFromList: (list, basePath) ->
		modules = []
		for module in @parseModulesList(list, basePath)
			modules.push(@findDependentModules(module))

		return Q.all(modules).then( (modules) ->
			result =
				files: []
				core: []
				node: {}

			for module in modules
				for name in module.files
					if result.files.indexOf(name) == -1 then result.files.push(name)
				for name in module.core
					if result.core.indexOf(name) == -1 then result.core.push(name)
				for name, info of module.node
					if typeof result.node[name] == 'undefined' then result.node[name] = info

			return Q.resolve(result)
		)


	@loadModules: (loader, modules, base) ->
		result = []
		for module in modules
			result.push(loader.loadModule(module, base))

		return Q.all(result)



	@findLibrariesFromList: (list, basePath) ->
		libraries = []
		for file in list
			if file.match(/^https?\:\/\//) == null
				file = path.resolve(basePath + '/' + file)
				if fs.existsSync(file)
					libraries.push(file)
				else
					libraries = libraries.concat(Finder.findFiles(file))
			else
				libraries.push(file)

		return libraries


	@loadLibraries: (loader, libraries, basePath) ->
		libraries = @findLibrariesFromList(libraries, basePath)

		result = []
		for library in libraries
			result.push(loader.loadFile(library))

		return Q.all(result)


module.exports = ApplicationHelpers