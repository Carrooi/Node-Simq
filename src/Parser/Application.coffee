_path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
Finder = require 'fs-finder'
fs = require 'fs'

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
			for alias, module of data.data.aliases
				data.result.modules.push('\'' + alias + '\': \'' + module + '\'')

			deferred = Q.defer()
			@loader.loadFile(__dirname + '/../Module.js').then( (content) ->
				content = content.replace(/\s+$/, '').replace(/;$/, '')
				data.result.final.push(content + '({' + data.result.modules.join(',\n') + '\n});')
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
		fns.push(fn) for i in [1..files.length]

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


module.exports = Application