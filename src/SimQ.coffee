fs = require 'fs'
watch = require 'watch'
_path = require 'path'
ncp = require 'ncp'
Loader = require './Loader'
Parser = require './Parser/Parser'
Configurator = require './Config/Configurator'
less = require 'less'

class SimQ


	basePath: '.'

	configPath: 'config/setup.json'

	config: null

	debug: false

	parser: null


	constructor: (@debug, configPath = null) ->
		if !configPath then configPath = @configPath
		@configPath = configPath

		@config = new Configurator(@basePath + '/' + @configPath, @debug)
		@parser = new Parser(@, new Loader(@), @basePath)


	build: ->
		config = @config.load()

		for name, pckg of config.packages
			((pckg) =>
				if pckg.application
					@parser.parseApplication(pckg, !config.debugger.scripts).then( (content) =>
						fs.writeFile(@basePath + '/' + pckg.application, content)
					)

				if pckg.style && pckg.style.in && pckg.style.out
					@parser.parseStyle(pckg.style.in, !config.debugger.styles).then( (content) =>
						fs.writeFile(@basePath + '/' + pckg.style.out, content)
					, (e) ->
						less.writeError(e)
					).done()
			)(pckg)

		return @


	watch: ->
		@build()

		ignore = new Array
		for name, pckg of @config.load().packages
			if pckg.application then ignore.push(_path.resolve(pckg.application))
			if pckg.style.out then ignore.push(_path.resolve(pckg.style.out))

		watch.watchTree(@basePath, {},  (file, curr, prev) =>
			if typeof file == 'string' && file.match(/~$/) == null && file.match(/^\./) == null && ignore.indexOf(_path.resolve(file)) == -1		# filter in option is not working...
				console.log file
				@config.invalidate()
				@build()
		)

		return @


	@create: (name) ->
		if !name then throw new Error 'Please enter name of new application.'

		path = _path.resolve(name)
		if fs.existsSync(path) then throw new Error 'Directory with ' + name + ' name is already exists.'

		ncp.ncp(_path.normalize(__dirname + '/../sandbox'), path, (err) ->
			if err then throw new Error 'There is some error with creating new application.'
		)


	getModuleName: (path) ->
		path = _path.normalize(path)
		return path.replace(new RegExp(_path.extname(path) + '$'), '')


module.exports = SimQ