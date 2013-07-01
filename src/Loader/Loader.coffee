Q = require 'q'
_path = require 'path'
fs = require 'fs'
http = require 'http'
Compilers = require './Compilers'

class Loader


	simq: null

	compilers: null


	constructor: (@simq) ->
		@compilers = new Compilers(@simq)


	loadFile: (path) ->
		if path.match(/^https?\:\/\//) == null then path = _path.resolve(path)

		if _path.basename(path, _path.extname(path)).substr(0, 1) == '.' || path.substring(path.length - 1) == '~'
			return Q.resolve(null)

		return ( ->
			deferred = Q.defer()

			ext = _path.extname(path).substr(1)

			if path.match(/^https?\:\/\//) == null
				path = _path.resolve(path)

				fs.readFile(path, 'utf-8', (e, data) ->
					if e then deferred.reject(new Error e) else deferred.resolve(ext: ext, content: data)
				)
			else
				http.get(path, (res) ->
					data = ''
					res.setEncoding('utf-8')
					res.on('data', (chunk) -> data += chunk )
					res.on('end', -> deferred.resolve(ext: ext, content: data))
				).on('error', (e) -> deferred.reject(new Error e))

			return deferred.promise
		)().then( (file) =>
			deferred = Q.defer()
			@compilers.prepare(path, file.content).then( (content) ->
				deferred.resolve(content)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		)


	loadModule: (path, base = null) ->
		return ( =>
			deferred = Q.defer()

			path = _path.resolve(path)
			ext = _path.extname(path).substr(1)

			if !@compilers.hasCompiler(ext)
				deferred.reject(new Error 'File type ' + ext + ' is not supported')
			else
				@loadFile(path).then((content) ->
					if content == null then deferred.resolve(null) else deferred.resolve(path: path, content: content)
				, (e) ->
					deferred.reject(e)
				)

			return deferred.promise
		)().then( (file) =>
			if file == null then return Q.resolve(null)

			deferred = Q.defer()
			name = @simq.getModuleName(file.path)

			if base != null then name = name.replace(new RegExp('^' + base + '/'), '')

			@compilers.compile(file.path, file.content).then( (content) ->
				deferred.resolve('\'' + name + '\': function(exports, _r, module) {\nvar require = function(name) {return _r(name, \'' + name + '\');};\n\t\t' + content + '\n\t}')
			)

			return deferred.promise
		)


	loadModules: (modules, base = null) ->
		deferred = Q.defer()
		@processModules([], modules, 0, base, (result) ->
			deferred.resolve(result)
		, (e) ->
			deferred.reject(e)
		)
		return deferred.promise


	getModulesInDir: (dir, type = null) ->
		dir = _path.resolve(dir)
		files = fs.readdirSync(dir)
		result = []

		for name in files
			name = dir + '/' + name
			stats = fs.statSync(name)

			if stats.isFile() && name.substring(name.length - 1) != '~'
				if type
					continue if _path.extname(name) != '.' + type

				result.push(name)
			else if stats.isDirectory()
				result = result.concat(@getModulesInDir(name, type))

		return result


	processModules: (result, files, num, base = null, finish, error) ->
		if files.length == 0 || num == files.length
			finish(result)
			return true

		@loadModule(files[num], base).then( (content) =>
			if content != null then result.push(content)
			@processModules(result, files, num + 1, base, finish, error)
		, (e) ->
			error(e)
		)


module.exports = Loader