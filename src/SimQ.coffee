fs = require 'fs'
coffee = require 'coffee-script'
eco = require 'eco'
watch = require 'watch'
_path = require 'path'
Loader = require './Loader'

class SimQ


	basePath: '.'

	config: null

	configPath: 'setup.json'

	debug: false

	modules: []

	loader: null


	constructor: ->
		@loader = new Loader @


	build: ->
		fs.writeFileSync(@basePath + '/' + @getConfig().main, @parse())

		return @


	watch: ->
		@build()

		watch.watchTree(@basePath, { persistent: true, interval: 1000 },  (file, curr, prev) =>
			@build() if curr and (curr.nlink is 0 or +curr.mtime isnt +prev?.mtime)
		)

		return @

	parse: ->
		result = new Array
		config = @getConfig()

		if config.libs && config.libs.begin
			for lib in config.libs.begin
				result.push(@loader.loadFile(@basePath + '/' + lib))

		if config.modules || config.aliases
			modules = new Array

			if config.modules
				for path in config.modules
					ext = _path.extname(path)
					name = path.replace(new RegExp('\\*?' + ext + '$'), '')
					ext = if ext == '' then null else ext.substring(1)

					if name.substring(name.length - 1) == '/'
						modules = modules.concat(@loader.loadModules(@basePath + '/' + name, ext))
					else
						modules.push(@loader.loadModule(@basePath + '/' + path))

			if config.aliases
				for alias, module of config.aliases
					if @modules.indexOf(module) == -1
						throw new Error 'Module ' + module + ' was not found.'

					@modules.push(alias)
					modules.push('\'' + alias + '\': \'' + module + '\'')

			module = @loader.loadFile(__dirname + '/Module.js').replace(/\s+$/, '').replace(/;$/, '')
			result.push(module + '({' + modules.join(',\n') + '\n});')

		if config.libs && config.libs.end
			for lib in config.libs.end
				result.push(@loader.loadFile(@basePath + '/' + lib))

		if config.run
			run = new Array
			for module in config.run
				if @modules.indexOf(module) == -1
					throw new Error 'Module ' + module + ' was not found.'

				run.push('this.require(\'' + module + '\');')

			result.push(run.join('\n'))

		result = result.join('\n\n')

		return result


	getModuleName: (path) ->
		path = _path.normalize(path)
		return path.replace(new RegExp(_path.extname(path) + '$'), '')


	getConfig: ->
		if @config == null
			if not fs.existsSync(@basePath + '/' + @configPath)
				throw new Error 'Config file setup.json was not found.'

			@config = JSON.parse(fs.readFileSync(@basePath + '/' + @configPath))

		return @config


module.exports = SimQ