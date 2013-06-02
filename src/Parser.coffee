Loader = require './Loader'
_path = require 'path'

class Parser


	basePath: null

	loader: null


	constructor: (@loader, @basePath) ->


	parseApplication: (section) ->
		result = new Array

		if section.libs && section.libs.begin
			for lib in section.libs.begin
				result.push(@loader.loadFile(@basePath + '/' + lib))

		if section.modules || section.aliases
			modules = new Array

			if section.modules
				for path in section.modules
					ext = _path.extname(path)
					name = path.replace(new RegExp('\\*?' + ext + '$'), '')
					ext = if ext == '' then null else ext.substring(1)

					if name.substring(name.length - 1) == '/'
						modules = modules.concat(@loader.loadModules(@basePath + '/' + name, ext))
					else
						modules.push(@loader.loadModule(@basePath + '/' + path))

			if section.aliases
				for alias, module of section.aliases
					modules.push('\'' + alias + '\': \'' + module + '\'')

			module = @loader.loadFile(__dirname + '/Module.js').replace(/\s+$/, '').replace(/;$/, '')
			result.push(module + '({' + modules.join(',\n') + '\n});')

		if section.libs && section.libs.end
			for lib in section.libs.end
				result.push(@loader.loadFile(@basePath + '/' + lib))

		if section.run
			run = new Array
			for module in section.run
				run.push('this.require(\'' + module + '\');')

			result.push(run.join('\n'))

		result = result.join('\n\n')

		return result


module.exports = Parser