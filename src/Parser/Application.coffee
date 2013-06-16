_path = require 'path'
Uglify = require 'uglify-js'

class Application


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @loader, @basePath) ->


	parse: (section, minify = true) ->
		result = new Array

		@addLibraries(section, 'begin', result)
		@addModules(section, result)
		@addLibraries(section, 'end', result)
		@addRun(section, result)

		result = result.join('\n\n')

		if minify then result = Uglify.minify(result, fromString: true).code

		return result


	addLibraries: (section, part, result) ->
		if section.libs && section.libs[part]
			for lib in section.libs[part]
				result.push(@loader.loadFile(@basePath + '/' + lib))


	addRun: (section, result) ->
		run = new Array
		for module in section.run
			run.push('this.require(\'' + module + '\');')

		result.push(run.join('\n'))


	addModules: (section, result) ->
		modules = new Array

		for path in section.modules
			ext = _path.extname(path)
			name = path.replace(new RegExp('\\*?' + ext + '$'), '')
			ext = if ext == '' then null else ext.substring(1)

			if name.substring(name.length - 1) == '/'
				modules = modules.concat(@loader.loadModules(@basePath + '/' + name, ext))
			else
				modules.push(@loader.loadModule(@basePath + '/' + path))

		for alias, module of section.aliases
			modules.push('\'' + alias + '\': \'' + module + '\'')

		module = @loader.loadFile(__dirname + '/../Module.js').replace(/\s+$/, '').replace(/;$/, '')
		result.push(module + '({' + modules.join(',\n') + '\n});')


module.exports = Application