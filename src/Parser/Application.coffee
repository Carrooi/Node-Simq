_path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'

class Application


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @loader, @basePath) ->


	parse: (section, minify = true) ->
		base = @basePath + '/' + (if section.base then section.base + '/' else '')

		processLib = (result, libs, num, finish) =>
			if libs.length == 0 || num == libs.length
				finish(result)
				return true
			file = if libs[num].match(/^https?\:\/\//) == null then base + libs[num] else libs[num]
			@loader.loadFile(file).then( (content) ->
				result.push(content)
				processLib(result, libs, num + 1, finish)
			)

		return ( ->
			return Q.resolve([])
		)().then( (result) =>
			deferred = Q.defer()
			processLib(result, section.libs.begin, 0, (result) -> deferred.resolve(result) )
			return deferred.promise
		).then( (result) =>
			buf = []

			for path in section.modules
				if section.base != null then path = './' + section.base + '/' + path

				ext = _path.extname(path)
				name = path.replace(new RegExp('\\*?' + ext + '$'), '')
				ext = if ext == '' then null else ext.substring(1)

				if name.substring(name.length - 1) == '/'
					buf = buf.concat(@loader.getModulesInDir(@basePath + '/' + name, ext))
				else
					buf.push(@basePath + '/' + path)

			deferred = Q.defer()
			@loader.loadModules(buf, section.base).then( (modules) ->
				deferred.resolve(result: result, modules: modules)
			)
			return deferred.promise
		).then( (data) =>
			for alias, module of section.aliases
				data.modules.push('\'' + alias + '\': \'' + module + '\'')

			deferred = Q.defer()
			@loader.loadFile(__dirname + '/../Module.js').then( (content) ->
				content = content.replace(/\s+$/, '').replace(/;$/, '')
				deferred.resolve(module: content, result: data.result, modules: data.modules)
			)
			return deferred.promise
		).then( (data) ->
			data.result.push(data.module + '({' + data.modules.join(',\n') + '\n});')
			return Q.resolve(data.result)
		).then( (result) =>
			deferred = Q.defer()
			processLib(result, section.libs.end, 0, (result) -> deferred.resolve(result) )
			return deferred.promise
		).then( (result) =>
			run = []
			for module in section.run
				run.push('this.require(\'' + module + '\');')

			result.push(run.join('\n'))

			return Q.resolve(result)
		).then( (result) =>
			result = result.join('\n\n')
			if minify then result = Uglify.minify(result, fromString: true).code

			return Q.resolve(result)
		)


module.exports = Application