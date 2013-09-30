fs = require 'fs'
watch = require 'watch'
path = require 'path'
ncp = require 'ncp'
express = require 'express'
Q = require 'q'
mime = require 'mime'
Parser = require './Parser/Parser'
Configurator = require './Config/Configurator'
Package = require './Package'
_Package = require './_Package'

class SimQ


	v: false		# verbose

	basePath: '.'

	configPath: 'config/setup.json'

	config: null

	debug: false

	parser: null

	pckg: null

	packages: null


	constructor: (configPath = @configPath, @basePath = @basePath) ->
		@packages = {}

		@basePath = path.resolve(@basePath)
		@configPath = path.resolve(@basePath + '/' + configPath)
		@pckg = new Package(@basePath)
		@config = new Configurator(@configPath, @pckg, @basePath)
		@parser = new Parser(@, @pckg, @basePath)


	hasPackage: (name) ->
		return typeof @packages[name] != 'undefined'


	addPackage: (name) ->
		if @hasPackage(name)
			throw new Error 'Package ' + name + ' is already registered.'

		@packages[name] = new _Package(@basePath)

		return @packages[name]


	_getPackage: (name) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		return @packages[name]


	removePackage: (name) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		delete @packages[name]
		return @


	server: ->
		app = express()
		config = @config.load()
		base = if config.routes.prefix == null then '/' else '/' + config.routes.prefix

		main = path.resolve(@basePath + '/' + config.routes.main)
		if fs.existsSync(main)
			console.log "Mapping file '#{main}' to '#{base}'" if @v
			app.get(base, (req, res) ->
				res.setHeader('Content-Type', 'text/html')
				res.sendfile(main)
			)

		for route, _path of config.routes.routes
			route = base + route
			_path = path.resolve(@basePath + '/' + _path)
			data = {route: route, path: _path}

			if fs.statSync(_path).isDirectory()
				console.log "Mapping directory '#{_path}' to '#{route}'" if @v
				app.use(route, express.static(_path))
			else
				((data) =>
					console.log "Mapping file '#{data.path}' to '#{data.route}'" if @v
					app.get(data.route, (req, res) ->
						res.setHeader('Content-Type', mime.lookup(data.path))
						res.sendfile(data.path)
					)
				)(data)

		for name, pckg of config.packages
			if pckg.skip == false
				pckg.name = name
				((pckg) =>
					if @hasPackageApplication(pckg.name)
						_path = base + path.relative(@basePath, pckg.application)
						console.log 'Mapping file \'' + path.resolve(pckg.application) + '\' to \'' + _path + '\'' if @v
						app.get(_path, (req, res) =>
							@buildApplication(pckg.name).then( (content) ->
								res.setHeader('Content-Type', 'application/javascript')
								res.send(content)
							)
						)

					if @hasPackageStyles(pckg.name)
						_path = base + path.relative(@basePath, pckg.style.out)
						console.log 'Mapping file \'' + path.resolve(pckg.style.out) + '\' to \'' + _path + '\'' if @v
						app.get(_path, (req, res) =>
							@buildStyles(pckg.name).then( (content) ->
								res.setHeader('Content-Type', 'text/css')
								res.send(content)
							)
						)
				)(pckg)

		app.listen(config.server.port)
		console.log 'Listening on port ' + config.server.port


	getPackage: (packageName) ->
		packages = @config.load().packages
		if typeof packages[packageName] == 'undefined'
			throw new Error 'Package ' + packageName + ' does not exists'

		return packages[packageName]


	hasPackageStyles: (packageName) ->
		pckg = @getPackage(packageName)
		return pckg.style && pckg.style.in && pckg.style.out


	hasPackageApplication: (packageName) ->
		pckg = @getPackage(packageName)
		return pckg.application != null


	buildStyles: (packageName) ->
		pckg = @getPackage(packageName)
		deferred = Q.defer()

		console.log "Building styles '#{packageName}'" if @v

		@parser.parseStyle(pckg).then( (content) =>
			deferred.resolve(content)
		, (e) ->
			throw e
		).done()

		return deferred.promise


	buildApplication: (packageName) ->
		pckg = @getPackage(packageName)
		deferred = Q.defer()

		console.log "Building package '#{packageName}'" if @v

		@parser.parseApplication(pckg).then( (content) =>
			deferred.resolve(content)
		, (e) ->
			throw e
		).done()

		return deferred.promise


	build: ->
		config = @config.load()

		for name, pckg of config.packages
			if pckg.skip == false
				pckg.name = name
				((pckg) =>
					if @hasPackageApplication(pckg.name)
						@buildApplication(pckg.name).then( (content) =>
							fs.writeFile(pckg.application, content)
						)

					if @hasPackageStyles(pckg.name)
						@buildStyles(pckg.name).then( (content) =>
							fs.writeFile(pckg.style.out, content)
						)
				)(pckg)

		return @


	watch: ->
		@build()

		ignore = new Array
		for name, pckg of @config.load().packages
			if pckg.application then ignore.push(path.resolve(pckg.application))
			if pckg.style.out then ignore.push(path.resolve(pckg.style.out))

		watch.watchTree(@basePath, {},  (file, curr, prev) =>
			if typeof file == 'string' && file.match(/~$/) == null && file.match(/^\./) == null && ignore.indexOf(path.resolve(file)) == -1		# filter in option is not working...
				console.log file if @v
				@build()
		)

		return @


	@create: (name) ->
		if !name then throw new Error 'Please enter name of new application.'

		_path = path.resolve(name)
		if fs.existsSync(_path) then throw new Error 'Directory with ' + name + ' name is already exists.'

		ncp.ncp(path.normalize(__dirname + '/../sandbox'), _path, (err) ->
			if err then throw new Error 'There is some error with creating new application.'
		)


	clean: ->
		config = @config.load()

		for name, pckg of config.packages
			if @hasPackageApplication(name) && fs.existsSync(pckg.application)
				console.log "Removing '#{pckg.application}' file" if @v
				fs.unlinkSync(pckg.application)

			if @hasPackageStyles(name) && fs.existsSync(pckg.style.out)
				console.log "Removing '#{pckg.style.out}' file" if @v
				fs.unlinkSync(pckg.style.out)

			if config.cache.directory != null
				_path = path.resolve(@basePath + '/' + config.cache.directory + '/__source_compiler.json')
				if fs.existsSync(_path)
					console.log "Removing temp files" if @v
					fs.unlinkSync(_path)


module.exports = SimQ