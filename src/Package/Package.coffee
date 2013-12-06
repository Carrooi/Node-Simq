Info = require 'module-info'
fs = require 'fs'
path = require 'path'
Finder = require 'fs-finder'

Helpers = require '../Helpers'

class Package


	@SUPPORTED = ['js', 'json', 'ts', 'coffee']

	@ALIAS_REGEXP = '^\\<([a-zA-Z0-9/-]+)\\|([a-zA-Z0-9/-]+)\\>$'


	basePath: null

	name: ''

	skip: false

	target: null

	paths: null

	ignore: null

	base: null

	style: null

	modules: null

	autoNpmModules: true

	aliases: null

	run: null

	info: null

	initialized: false

	logger: null


	constructor: (@basePath) ->
		@basePath = path.resolve(@basePath)

		@paths =
			package: './package.json'
			npmModules: './node_modules'

		@ignore =
			package: false
			main: false

		@modules = []
		@aliases = {}
		@run = []


	log: (message) ->
		if @logger != null
			return @logger.log(message)

		return message


	prepare: ->
		if @initialized == false
			if !@ignore.package
				@addModule(@getPackageInfo().getPackagePath())

			if !@ignore.main
				main = @getPackageInfo().getMainFile()
				if main != null
					@log "Adding #{main} module"
					@addModule(main)

			dependencies = @getPackageInfo().getData().dependencies
			if typeof dependencies == 'object' && @autoNpmModules
				@log "Adding npm dependencies"

				if !fs.existsSync(@getPath(@paths.npmModules))
					throw new Error "Npm modules not found. Did you run 'npm install .' command?"

				for name of dependencies
					_path = @getPath(@paths.npmModules + '/' + name)
					if !fs.existsSync(_path)
						throw new Error "Npm module '#{name}' not found. Did you run 'npm install .' command?"

					pckg = new Info(_path)

					name = pckg.getPackagePath()
					@log "Adding #{name} module"
					@addModule(name)
					main = pckg.getMainFile()
					if main != null
						@log "Adding #{main} module"
						@addModule(main)

			@initialized = true


	getBasePath: ->
		return @basePath + (if @base == null then '' else '/' + @base)


	getPath: (_path) ->
		return path.resolve(@getBasePath() + '/' + _path)


	getPackageInfo: ->
		if @info == null
			@info = new Info(path.dirname(@getPath(@paths.package)))

		return @info


	expandPaths: (paths) ->
		result = []
		for _path in paths
			if _path.match(/^http/) == null
				_path = @getPath(_path)
				if fs.existsSync(_path) && fs.statSync(_path).isFile()
					result.push(_path)
				else
					result = result.concat(Finder.findFiles(_path))
			else
				result.push(_path)

		return result.filter( (el, pos) -> return result.indexOf(el) == pos)


	setTarget: (@target) ->
		@target = @getPath(@target)
		return @


	setStyle: (fileIn, fileOut, dependencies = null) ->
		fileIn = @getPath(fileIn)
		fileOut = @getPath(fileOut)

		if !fs.existsSync(fileIn)
			throw new Error 'File ' + fileIn + ' does not exists.'

		if dependencies != null
			dependencies = @expandPaths(dependencies)

		@style =
			in: fileIn
			out: fileOut
			dependencies: dependencies

		return @


	addModule: (name) ->
		found = false

		# modules registered with absolute path
		if name[0] == '/'
			if fs.existsSync(name)
				found = true
				if fs.statSync(name).isDirectory()
					pckg = new Info(name)
					main = pckg.getMainFile()
					if main != null then @modules.push(main)
					@modules.push(pckg.getPackagePath())
				else
					@modules.push(name)
			else
				paths = Finder.findFiles(name)
				if paths.length > 0
					found = true
					for _path in paths
						@addModule(_path)

		# core node modules
		if found == false
			_path = Helpers.getCoreModulePath(name)
			if _path != null
				found = true
				@modules.push(_path)
			else if require('../../data.json').supportedCores.indexOf(name) != -1
				throw new Error "Core module #{name} was not found."

		# own modules from project
		if name[0] == '.' && found == false
			_path = @getPath(name)
			if fs.existsSync(_path)
				found = true
				@modules.push(_path)
			else
				paths = Finder.findFiles(_path)
				found = true
				for _path in paths
					_path = path.relative(@getBasePath(), _path)
					@addModule('./' + _path)

		# npm modules in node_modules directory
		if found == false
			_path = @getPath(@paths.npmModules + '/' + name)
			if fs.existsSync(_path)
				if fs.statSync(_path).isFile()
					found = true
					@modules.push(_path)
				else
					paths = Finder.from(_path).findFiles('*.js')
					if paths.length > 0
						found = true
						for _path in paths
							_path = path.relative(@getPath(@paths.npmModules), _path)
							@addModule(_path)
			else
				paths = Finder.findFiles(_path)
				if paths.length > 0
					found = true
					for _path in paths
						_path = path.relative(@getPath(@paths.npmModules), _path)
						@addModule(_path)

		if found == false
			throw new Error 'Module ' + name + ' was not found.'

		return @


	addAlias: (original, alias) ->
		@aliases[alias] = original
		return @


	addToAutorun: (name) ->
		if name.match(/^\<.+\>$/) != null
			throw new Error 'Inline code in run section is not supported. Please, put that code into module.'

		# module to run
		if name.match(/^-\s/) == null
			@run.push(name)

		# file path
		else
			name = name.replace(/^-\s/, '')
			name = path.resolve(@getBasePath(), name)
			if fs.existsSync(name)
				@run.push(name)
			else
				files = Finder.findFiles(name)
				if files.length == 0
					throw new Error 'Library to run ' + name + ' was not found.'

				for file in files
					@addToAutorun(file)

		return @


module.exports = Package