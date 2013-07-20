_path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
Finder = require 'fs-finder'
fs = require 'fs'
required = require 'required'

class Application


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @loader, @basePath) ->


	parse: (section, packageName) ->
		base = @basePath + '/' + (if section.base then section.base + '/' else '')

		data =
			data: section
			result:
				modules: []
				nodeModules: {}
				final: []

		return Q.resolve(data).then( (data) =>
			deferred = Q.defer()
			@loadFiles(data.data.libs.begin, base).then( (result) ->
				data.result.final = result
				deferred.resolve(data)
			)
			return deferred.promise
		).then( (data) =>
			modules = @findModules(section.modules, section.base)

			deferred = Q.defer()
			@loader.loadModules(modules, section.base).then( (modules) ->
				data.result.modules = modules
				deferred.resolve(data)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		).then( (data) =>
			if fs.existsSync(@basePath + '/node_modules')
				deferred = Q.defer()
				@findNodeModules().then( (modulesData) =>
					info = {}
					for infoData in modulesData.info
						info[infoData.moduleBase] =
							name: infoData.module
							path: infoData.modulePath
					data.result.nodeModules = info

					@loader.loadModules(modulesData.files).then( (modules) ->
						data.result.modules = data.result.modules.concat(modules)
						deferred.resolve(data)
					)
				)
				return deferred.promise
			else
				return Q.resolve(data)
		).then( (data) =>
			for alias, module of data.data.aliases
				data.result.modules.push('\'' + alias + '\': \'' + module + '\'')

			deferred = Q.defer()
			@loader.loadFile(__dirname + '/../Module.js').then( (content) ->
				content = content.replace(/\s+$/, '').replace(/;$/, '')
				data.result.final.push(content + '({' + data.result.modules.join(',\n') + '\n});')
				data.result.final.push('require._setNodeInfo(' + JSON.stringify(data.result.nodeModules) + ');\n')
				deferred.resolve(data)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		).then( (data) =>
			deferred = Q.defer()
			@loadFiles(data.data.libs.end, base).then( (result) ->
				data.result.final = data.result.final.concat(result)
				deferred.resolve(data)
			)
			return deferred.promise
		).then( (data) =>
			run = []
			for module in section.run
				run.push('this.require(\'' + module + '\');')

			data.result.final.push(run.join('\n'))

			return Q.resolve(data)
		).then( (data) =>
			result = data.result.final.join('\n\n')
			if !@simq.config.load().debugger.scripts then result = Uglify.minify(result, fromString: true).code

			return Q.resolve(result)
		)


	loadFiles: (files, base) ->
		data =
			result: []
			progress: null
			files: files

		fn = (data) =>
			deferred = Q.defer()
			actual = if data.progress == null then 0 else data.progress
			file = if data.files[actual].match(/^https?\:\/\//) == null then base + data.files[actual] else data.files[actual]
			@loader.loadFile(file).then( (content) ->
				if content != null then data.result.push(content)
				deferred.resolve(data)
			, (e) ->
				deferred.reject(e)
			)
			data.progress++
			return deferred.promise

		fns = []
		if files.length > 0
			fns.push(fn) for i in [0..files.length - 1]

		deferred = Q.defer()
		buf = fns.reduce( (soFar, f) ->
			return soFar.then(f)
		, Q.resolve(data))
		buf.then((libs) -> deferred.resolve(libs.result) )
		return deferred.promise


	findModules: (paths, base = null) ->
		result = []

		for path in paths
			if base != null then path = './' + base + '/' + path
			path = _path.resolve(@basePath + '/' + path)

			if fs.existsSync(path) && fs.statSync(path).isFile()
				result.push(path)
			else
				filter = (stat, file) -> return file.substr(file.length - 1) != '~'
				path = Finder.parseDirectory(path)
				result = result.concat((new Finder(path.directory)).recursively().filter(filter).findFiles(path.mask))

		return result


	findNodeModules: ->
		deferred = Q.defer()
		modules =
			files: []
			info: []

		for file in Finder.findFiles(_path.resolve(@basePath + '/node_modules/*/package.json'))
			info = @getMainNodeModule(file, JSON.parse(fs.readFileSync(file, encoding: 'utf8')))
			modules.files.push(info.file)
			modules.info.push(info)

		@loadNodeModuleDependencies(modules.files).then( (files) =>
			deferred.resolve(files: files, info: modules.info)
		)

		return deferred.promise


	findNodeFile: (path) ->
		path = _path.resolve(path)
		if fs.existsSync(path)
			if fs.statSync(path).isDirectory()
				return @findNodeFile(path + '/index')
			else
				return path
		else if fs.existsSync(path + '.js')
			return path + '.js'
		else if fs.existsSync(path + '.json')
			return path + '.json'
		else
			return null


	loadNodeModuleDependencies: (files) ->
		data =
			result: []
			progress: null
			files: files

		fn = (data) =>
			deferred = Q.defer()
			actual = if data.progress == null then 0 else data.progress
			data.result.push(data.files[actual])
			required(data.files[actual], ignoreMissing: true, (e, deps) =>
				if e
					deferred.reject(e)
				else
					result = []
					for dep in deps
						if dep.core != true
							result.push(dep.filename)
							if dep.deps.length > 0
								result = result.concat(@parseDependencies(dep))
					result = result.filter( (el, pos, self) ->
						return self.indexOf(el) == pos
					)

					data.result = data.result.concat(result)
					deferred.resolve(data)
			)

			data.progress++
			return deferred.promise

		fns = []
		fns.push(fn) for i in [1..files.length]

		deferred = Q.defer()
		buf = fns.reduce( (soFar, f) ->
			return soFar.then(f)
		, Q.resolve(data))
		buf.then((data) -> deferred.resolve(data.result) W)
		return deferred.promise


	getMainNodeModule: (file, pckgInfo) ->
		result =
			file: null
			moduleBase: null
			modulePath: null
			module: null

		main = if typeof pckgInfo.main == 'undefined' then './index' else pckgInfo.main
		main = _path.resolve(_path.dirname(file), main)
		result.file = main = @findNodeFile(main)

		result.moduleBase = _path.relative(@basePath, _path.dirname(file))

		main = _path.relative(_path.resolve(@basePath), main)
		result.modulePath = main.substring(0, main.length - _path.extname(main).length)

		match = result.modulePath.match(/node_modules\/([a-z0-9-_]+)/g)
		result.module = match[match.length - 1].split('/')[1]

		return result


	parseDependencies: (dep) ->
		result = []
		for sub in dep.deps
			if sub.core != true
				result.push(sub.filename)
				if sub.deps.length > 0
					result = result.concat(@parseDependencies(sub))
		return result




module.exports = Application