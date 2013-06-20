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

		return ( ->
			deferred = Q.defer()
			deferred.resolve(new Array)
			return deferred.promise
		)().then( (result) =>
			for lib in section.libs.begin
				result.push(@loader.loadFile(base + lib))

			deferred = Q.defer()
			deferred.resolve(result)
			return deferred.promise
		).then( (result) =>
			modules = new Array

			for path in section.modules
				if section.base != null then path = './' + section.base + '/' + path

				ext = _path.extname(path)
				name = path.replace(new RegExp('\\*?' + ext + '$'), '')
				ext = if ext == '' then null else ext.substring(1)

				if name.substring(name.length - 1) == '/'
					modules = modules.concat(@loader.loadModules(@basePath + '/' + name, ext, section.base))
				else
					modules.push(@loader.loadModule(@basePath + '/' + path, section.base))

			for alias, module of section.aliases
				modules.push('\'' + alias + '\': \'' + module + '\'')

			module = @loader.loadFile(__dirname + '/../Module.js').replace(/\s+$/, '').replace(/;$/, '')
			result.push(module + '({' + modules.join(',\n') + '\n});')

			deferred = Q.defer()
			deferred.resolve(result)
			return deferred.promise
		).then( (result) =>
			for lib in section.libs.end
				result.push(@loader.loadFile(base + lib))

			deferred = Q.defer()
			deferred.resolve(result)
			return deferred.promise
		).then( (result) =>
			run = new Array
			for module in section.run
				run.push('this.require(\'' + module + '\');')

			result.push(run.join('\n'))

			deferred = Q.defer()
			deferred.resolve(result)
			return deferred.promise
		).then( (result) =>
			result = result.join('\n\n')
			if minify then result = Uglify.minify(result, fromString: true).code

			deferred = Q.defer()
			deferred.resolve(result)
			return deferred.promise
		)


module.exports = Application