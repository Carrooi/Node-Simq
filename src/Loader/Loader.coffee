Q = require 'q'
_path = require 'path'
fs = require 'fs'
http = require 'http'
https = require 'https'
Cache = require 'cache-storage'
FileStorage = require 'cache-storage/Storage/FileStorage'
Finder = require 'fs-finder'
Compilers = require './Compilers'

class Loader


	@CACHE_NAMESPACE = 'simq.files'


	simq: null

	compilers: null

	cache: null


	constructor: (@simq) ->
		@compilers = new Compilers(@simq)

		cacheDirectory = @simq.config.load().cache.directory
		if cacheDirectory != null
			@cache = new Cache(new FileStorage(_path.resolve(cacheDirectory)), Loader.CACHE_NAMESPACE)


	isCacheAllowed: (path, packageName = null) ->
		return false if @cache == null
		return false if path.match(/^https?\:\/\//) != null
		return true if _path.extname(path) not in ['.less', '.scss', '.styl']
		return false if packageName == null

		dependencies = @simq.config.load().packages[packageName].style.dependencies

		return if dependencies.length > 0 then dependencies else false


	loadFromPath: (path) ->
		deferred = Q.defer()
		ext = _path.extname(path).substr(1)

		if path.match(/^https?\:\/\//) == null
			path = _path.resolve(path)

			fs.readFile(path, 'utf-8', (e, data) ->
				if e then deferred.reject(new Error e) else deferred.resolve(path: path, ext: ext, content: data)
			)
		else
			protocol = if path.match(/^https/) == null then http else https
			protocol.get(path, (res) ->
				data = ''
				res.setEncoding('utf-8')
				res.on('data', (chunk) -> data += chunk )
				res.on('end', -> deferred.resolve(path: path, ext: ext, content: data))
			).on('error', (e) -> deferred.reject(new Error e))

		return deferred.promise


	finalizeFile: (path, content, packageName) ->
		deferred = Q.defer()

		@compilers.prepare(path, content).then( (content) =>
			if (dependencies = @isCacheAllowed(path, packageName)) != false && @cache.load(path) == null
				files = [path]
				if dependencies != true
					for path in dependencies
						files = files.concat(Finder.findFiles(path))

				@cache.save(path, content,
					files: files
				)

			deferred.resolve(content)
		, (e) ->
			deferred.reject(e)
		)

		return deferred.promise


	loadFile: (path, packageName = null) ->
		if path.match(/^https?\:\/\//) == null then path = _path.resolve(path)

		if _path.basename(path, _path.extname(path)).substr(0, 1) == '.' || path.substring(path.length - 1) == '~'
			return Q.resolve(null)

		if @isCacheAllowed(path, packageName) != false && (data = @cache.load(path)) != null
			return Q.resolve(data)

		deferred = Q.defer()

		@loadFromPath(path).then( (data) =>
			@finalizeFile(data.path, data.content, packageName).then( (content) ->
				deferred.resolve(content)
			)
		)

		return deferred.promise


	prepareModule: (path) ->
		deferred = Q.defer()

		path = _path.resolve(path)
		ext = _path.extname(path).substr(1)

		if !@compilers.hasCompiler(ext)
			deferred.reject(new Error 'File type ' + ext + ' is not supported')
		else
			@loadFile(path).then((content) ->
				if content == null
					deferred.resolve(null)
				else
					deferred.resolve(path: path, content: content)
			, (e) ->
				deferred.reject(e)
			)

		return deferred.promise


	loadModule: (path, base = null) ->
		deferred = Q.defer()

		@prepareModule(path).then( (data) =>
			if data == null
				deferred.resolve(null)
			else
				name = @simq.getModuleName(data.path)

				if base != null then name = name.replace(new RegExp('^' + base + '/'), '')

				@compilers.compile(data.path, data.content).then( (content) ->
					deferred.resolve('\'' + name + '\': function(exports, _r, module) {\nvar require = function(name) {return _r(name, \'' + name + '\');};\n\t\t' + content + '\n\t}')
				)
		)

		return deferred.promise


module.exports = Loader