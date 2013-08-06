fs = require 'fs'
watch = require 'watch'
_path = require 'path'
ncp = require 'ncp'
express = require 'express'
Q = require 'q'
mime = require 'mime'
Parser = require './Parser/Parser'
Configurator = require './Config/Configurator'

class SimQ


	v: false		# verbose

	basePath: '.'

	configPath: 'config/setup.json'

	config: null

	debug: false

	parser: null


	constructor: (@debug = false, @basePath = '.', configPath = null) ->
		if !configPath then configPath = @configPath
		@configPath = _path.resolve(@basePath + '/' + configPath)

		@config = new Configurator(@configPath, @debug)
		@parser = new Parser(@, @basePath)


	server: ->
		app = express()
		config = @config.load()
		base = if config.routes.prefix == null then '/' else '/' + config.routes.prefix

		main = _path.resolve(@basePath + '/' + config.routes.main)
		if fs.existsSync(main)
			console.log "Mapping file '#{main}' to '#{base}'" if @v
			app.get(base, (req, res) ->
				res.setHeader('Content-Type', 'text/html')
				res.sendfile(main)
			)

		for route, path of config.routes.routes
			route = base + route
			path = _path.resolve(@basePath + '/' + path)
			data = {route: route, path: path}

			if fs.statSync(path).isDirectory()
				console.log "Mapping directory '#{path}' to '#{route}'" if @v
				app.use(route, express.static(path))
			else
				((data) =>
					console.log "Mapping file '#{data.path}' to '#{data.route}'" if @v
					app.get(data.route, (req, res) ->
						res.setHeader('Content-Type', mime.lookup(data.path))
						res.sendfile(data.path)
					)
				)(data)

		for name, pckg of config.packages
			pckg.name = name
			((pckg) =>
				if @hasPackageApplication(pckg.name)
					console.log 'Mapping file \'' + _path.resolve(pckg.application) + '\' to \'' + base + _path.normalize(pckg.application) + '\'' if @v
					app.get(base + _path.normalize(pckg.application), (req, res) =>
						@buildApplication(pckg.name).then( (content) ->
							res.setHeader('Content-Type', 'application/javascript')
							res.send(content)
						)
					)

				if @hasPackageStyles(pckg.name)
					console.log 'Mapping file \'' + _path.resolve(pckg.style.out) + '\' to \'' + base + _path.normalize(pckg.style.out) + '\'' if @v
					app.get(base + _path.normalize(pckg.style.out), (req, res) =>
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
		return pckg.application


	buildStyles: (packageName) ->
		pckg = @getPackage(packageName)
		deferred = Q.defer()

		console.log "Building styles '#{packageName}'" if @v

		@parser.parseStyle(pckg.style.in, pckg.name).then( (content) =>
			deferred.resolve(content)
		, (e) ->
			throw e
		).done()

		return deferred.promise


	buildApplication: (packageName) ->
		pckg = @getPackage(packageName)
		deferred = Q.defer()

		console.log "Building package '#{packageName}'" if @v

		@parser.parseApplication(pckg, pckg.name).then( (content) =>
			deferred.resolve(content)
		, (e) ->
			throw e
		).done()

		return deferred.promise


	build: ->
		config = @config.load()

		for name, pckg of config.packages
			pckg.name = name
			((pckg) =>
				if @hasPackageApplication(pckg.name)
					@buildApplication(pckg.name).then( (content) =>
						fs.writeFile(@basePath + '/' + pckg.application, content)
					)

				if @hasPackageStyles(pckg.name)
					@buildStyles(pckg.name).then( (content) =>
						fs.writeFile(@basePath + '/' + pckg.style.out, content)
					)
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
				console.log file if @v
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


module.exports = SimQ