_path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
Finder = require 'fs-finder'

class Application


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @loader, @basePath) ->


	parse: (section) ->
		base = @basePath + '/' + (if section.base then section.base + '/' else '')

		processLib = (result, libs, num, finish, error) =>
			if libs.length == 0 || num == libs.length
				finish(result)
				return true
			file = if libs[num].match(/^https?\:\/\//) == null then base + libs[num] else libs[num]
			@loader.loadFile(file).then( (content) ->
				if content != null then result.push(content)
				processLib(result, libs, num + 1, finish, error)
			, (e) ->
				error(e)
			)

		return ( ->
			return Q.resolve([])
		)().then( (result) =>
			deferred = Q.defer()
			processLib(result, section.libs.begin, 0, (result) ->
				deferred.resolve(result)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		).then( (result) =>
			buf = []

			for path in section.modules
				if section.base != null then path = './' + section.base + '/' + path
				filter = (stat, file) -> return file.substr(file.length - 1) != '~'

				if (asterisk = path.indexOf('*')) != -1
					baseDir = _path.resolve(path.substr(0, asterisk))
					mask = path.substr(asterisk)
					buf = buf.concat((new Finder(baseDir)).recursively().filter(filter).findFiles(mask))
				else if path.substr(path.length - 1) == '/'
					buf = buf.concat((new Finder(_path.resolve(path))).recursively().filter(filter).findFiles())
				else
					buf.push(@basePath + '/' + path)

			deferred = Q.defer()
			@loader.loadModules(buf, section.base).then( (modules) ->
				deferred.resolve(result: result, modules: modules)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		).then( (data) =>
			for alias, module of section.aliases
				data.modules.push('\'' + alias + '\': \'' + module + '\'')

			deferred = Q.defer()
			@loader.loadFile(__dirname + '/../Module.js').then( (content) ->
				content = content.replace(/\s+$/, '').replace(/;$/, '')
				deferred.resolve(module: content, result: data.result, modules: data.modules)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		).then( (data) ->
			data.result.push(data.module + '({' + data.modules.join(',\n') + '\n});')
			return Q.resolve(data.result)
		).then( (result) =>
			deferred = Q.defer()
			processLib(result, section.libs.end, 0, (result) ->
				deferred.resolve(result)
			, (e) ->
				deferred.reject(e)
			)
			return deferred.promise
		).then( (result) =>
			run = []
			for module in section.run
				run.push('this.require(\'' + module + '\');')

			result.push(run.join('\n'))

			return Q.resolve(result)
		).then( (result) =>
			result = result.join('\n\n')
			if !@simq.config.load().debugger.scripts then result = Uglify.minify(result, fromString: true).code

			return Q.resolve(result)
		)


module.exports = Application