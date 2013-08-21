fs = require 'fs'
path = require 'path'
Q = require 'q'
required = require 'required'
Finder = require 'fs-finder'
Helpers = require './Helpers'

class Package


	basePath: null


	constructor: (@basePath) ->


	isInModule: (_path) ->
		pckg = Finder.in(path.dirname(_path)).lookUp(@basePath).findFirst().findFiles('package.json')
		return pckg != null && pckg != @basePath + '/package.json'


	getModuleName: (_path) ->
		if !@isInModule(_path)
			return null

		if _path.match(/package\.json$/) == null
			buf = _path.substr(_path.lastIndexOf('/node_modules/') + 14)
			return buf.substr(0, buf.indexOf('/'))
		else
			buf = _path.substr(0, _path.length - 13)
			return buf.substr(buf.lastIndexOf('/') + 1)



	getModuleBaseDir: (_path) ->
		if !@isInModule(_path)
			return null

		if _path.match(/package\.json$/) == null
			return _path.substr(0, _path.lastIndexOf('/node_modules/') + 14) + @getModuleName(_path)
		else
			return _path.substr(0, _path.length - 13)


	resolveModuleName: (_path) ->
		_path = path.resolve(_path)
		if fs.existsSync(_path)
			if fs.statSync(_path).isDirectory()
				return @resolveModuleName(_path + '/index')
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


	findModulePackageFile: (_path) ->
		if !@isInModule(_path)
			return null

		return @getModuleBaseDir(_path) + '/package.json'


	loadModuleInfo: (_path) ->
		if !@isInModule(_path)
			return null

		pckg = @findModulePackageFile(_path)
		pckg = JSON.parse(fs.readFileSync(pckg, encoding: 'utf8'))

		main = if typeof pckg.main == 'undefined' then './index' else pckg.main
		dir = @getModuleBaseDir(_path)
		main = dir + '/' + main
		main = @resolveModuleName(main)

		result =
			file: _path
			name: @getModuleName(_path)
			main: path.normalize(main)
			dir: dir

		return result


	findDependencies: (_path) ->
		if path.extname(_path) != '.js'
			result =
				files: [_path]
				core: []
				node: {}
			if (info = @loadModuleInfo(_path)) != null
				result.node[info.dir] =
					name: info.name
					main: info.main

			return Q.resolve(result)

		deferred = Q.defer()
		required(_path, ignoreMissing: true, (e, deps) =>
			if e
				deferred.reject(e)
			else
				res =
					files: [_path]
					core: []
					node: {}

				for dep in deps
					ext = @parseDependencies(dep)
					res.files = res.files.concat(ext.files)
					res.core = res.core.concat(ext.core)

				for file in res.files
					if (info = @loadModuleInfo(file)) != null
						res.files.push(info.main)
						res.node[info.dir] =
							name: info.name
							main: info.main

				res.files = Helpers.removeDuplicates(res.files)
				res.core = Helpers.removeDuplicates(res.core)

				deferred.resolve(res)
		)
		return deferred.promise


	parseDependencies: (dep) ->
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


	findDependenciesForModules: (paths) ->
		modules = []
		for _path in paths
			modules.push(@findDependencies(_path))

		return Q.all(modules).then( (modules) ->
			result =
				files: []
				core: []
				node: {}

			for m in modules
				for name in m.files
					if result.files.indexOf(name) == -1 then result.files.push(name)
				for name in m.core
					if result.core.indexOf(name) == -1 then result.core.push(name)
				for name, info of m.node
					if typeof result.node[name] == 'undefined' then result.node[name] = info

			return Q.resolve(result)
		)


	getGlobalsForModule: (name) ->
		globals =
			require: "function(name) {return __require(name, '#{name}');}"
			__filename: "'#{name}'"
			__dirname: '\'' + path.dirname(name) + '\''

		result = []
		for key, value of globals
			result.push("var #{key} = #{value};")

		return result


	parseNodeInfo: (data, basePath) ->
		result = {}

		for m, info of data
			main = path.relative(basePath, info.main)
			name = path.relative(basePath, m)

			main = main.replace(/^[./]+/, '')
			name = name.replace(/^[./]+/, '')

			result[name] =
				name: info.name
				path: main

		return result


module.exports = Package