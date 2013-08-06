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
					ext = @parseDependencies(dep)
					res.files = res.files.concat(ext.files)
					res.core = res.core.concat(ext.core)

				for file in res.files
					if (info = @findPackageInfo(file)) != null
						res.files.push(info.main)
						res.node[info.dir] =
							name: info.name
							main: info.main

				res.files = @removeDuplicates(res.files)
				res.core = @removeDuplicates(res.core)

				deferred.resolve(res)
		)
		return deferred.promise


	@parseDependencies: (dep) ->
		result =
			files: []
			core: []

		if dep.core == true
			result.core.push(dep.id)
		else
			result.files.push(dep.filename)
			for sub in dep.deps
				ext = @parseDependencies(sub)
				result.files = result.files.concat(ext.files)
				result.core = result.core.concat(ext.core)

		return result


	@isInModule: (file) ->
		return file.lastIndexOf('/node_modules/') != -1


	@getModuleName: (file) ->
		if !@isInModule(file)
			return null

		buf = file.substr(file.lastIndexOf('/node_modules/') + 14)
		return buf.substr(0, buf.indexOf('/'))


	@getModuleBaseDir: (file) ->
		if !@isInModule(file)
			return null

		return file.substr(0, file.lastIndexOf('/node_modules/') + 14) + @getModuleName(file)


	@resolveNodeFile: (_path) ->
		_path = path.resolve(_path)
		if fs.existsSync(_path)
			if fs.statSync(_path).isDirectory()
				return @resolveNodeFile(_path + '/index')
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
		if !@isInModule(file)
			return null

		return @getModuleBaseDir(file) + '/package.json'


	@findPackageInfo: (file) ->
		if !@isInModule(file)
			return null

		pckg = @findNodePackage(file)
		pckg = JSON.parse(fs.readFileSync(pckg, encoding: 'utf8'))

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


	@parseModulesList: (list, basePath) ->
		modules = []
		for module in list
			module = path.resolve(basePath + '/' + module)
			if fs.existsSync(module)
				modules.push(module)
			else
				modules = modules.concat(Finder.findFiles(module))

		modules = @removeDuplicates(modules)

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

		libraries = @removeDuplicates(libraries)

		return libraries


	@loadLibraries: (loader, libraries, basePath) ->
		libraries = @findLibrariesFromList(libraries, basePath)

		result = []
		for library in libraries
			result.push(loader.loadFile(library))

		return Q.all(result)


	@removeDuplicates: (array) ->
		return array.filter( (el, pos) -> return array.indexOf(el) == pos)


	@translateNodeModulesList: (list) ->
		list[i] = "./node_modules/#{m}" for m, i in list
		return list


module.exports = ApplicationHelpers