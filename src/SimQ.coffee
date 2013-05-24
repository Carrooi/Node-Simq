fs = require 'fs'
coffee = require 'coffee-script'
eco = require 'eco'
watch = require 'watch'

class SimQ


	basePath: '.'

	config: null

	configPath: 'setup.json'

	supported: ['js', 'coffee', 'json', 'eco']

	debug: false

	modules: []


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

		result.push(@loadLibrary(__dirname + '/Module.js'))

		if config.libs && config.libs.begin
			for lib in config.libs.begin
				result.push(@loadLibrary(@basePath + '/' + lib))

		if config.modules
			supported = new RegExp('\\*\\.(' + @supported.join('|') + ')$', 'i')

			for name in config.modules
				ext = name.match(supported)

				if ext
					extension = ext[1]
					name = name.replace(supported, '')

				if name.substr(name.length - 1) == '/'
					result = result.concat(@loadModules(@basePath + '/' + name, extension))
					extension = null
				else
					result.push(@loadModule(@basePath + '/' + name))

		if config.libs && config.libs.end
			for lib in config.libs.end
				result.push(@loadLibrary(@basePath + '/' + lib))

		if config.aliases
			for alias, module of config.aliases
				if @modules.indexOf(module) == -1
					throw new Error 'Module ' + module + ' was not found.'

				result.push('this._module.addAlias(\'' + alias + '\', \'' + module + '\');')

		result = result.join('\n\n')

		return result


	loadModules: (dir, extension = null) ->
		files = fs.readdirSync(dir)
		result = new Array

		for name in files
			name = dir + name
			stats = fs.statSync(name)

			if stats.isFile() && name.substring(name.length - 1) != '~'
				if extension
					continue if name.substring(name.lastIndexOf('.') + 1).toLowerCase() != extension

				result.push(@loadModule(name))
			else if stats.isDirectory()
				result = result.concat(@loadModules(name + '/', extension))

		return result


	loadModule: (name) ->
		lib = @loadLibrary(name)

		lib = lib.replace(/\n/g, '\n\t\t')
		lib = '\t' + lib

		if name.substr(0, @basePath.length) == @basePath
			name = name.substring(@basePath.length)

		supported = new RegExp('\\.(' + @supported.join('|') + ')$', 'i')

		name = name.replace(/^(\/)?(.\/)*/, '')
		name = name.replace(supported, '')

		@modules.push(name)

		return 'this._module.register(\'' + name + '\',\n\t(function(module) {\n\t\treturn ' + lib + '\n\t})\n);'


	loadLibrary: (path) ->
		extension = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
		if @supported.indexOf(extension) == -1
			return ''

		file = fs.readFileSync(path).toString()

		switch extension
			when 'coffee' then file = coffee.compile(file)
			when 'eco' then file = eco.precompile(file)

		file = file.replace(/^\s+|\s+$/g, '')

		return file


	getConfig: ->
		if @config == null
			if not fs.existsSync(@basePath + '/' + @configPath)
				throw new Error 'Config file setup.json was not found.'

			@config = JSON.parse(fs.readFileSync(@basePath + '/' + @configPath))

		return @config


module.exports = SimQ