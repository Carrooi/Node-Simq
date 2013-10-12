fs = require 'fs'
ncp = require 'ncp'
path = require 'path'
express = require 'express'
Compiler = require 'source-compiler'
EventEmitter = require('events').EventEmitter

class Commands extends EventEmitter


	simq: null


	constructor: (@simq) ->


	server: ->
		###app = express()
		config = @config.load()
		base = if config.routes.prefix == null then '/' else '/' + config.routes.prefix

		main = path.resolve(@basePath + '/' + config.routes.main)
		if fs.existsSync(main)
			app.get(base, (req, res) ->
				res.setHeader('Content-Type', 'text/html')
				res.sendfile(main)
			)

		for route, _path of config.routes.routes
			route = base + route
			_path = path.resolve(@basePath + '/' + _path)
			data = {route: route, path: _path}

			if fs.statSync(_path).isDirectory()
				app.use(route, express.static(_path))
			else
				((data) =>
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
						app.get(_path, (req, res) =>
							@buildApplication(pckg.name).then( (content) ->
								res.setHeader('Content-Type', 'application/javascript')
								res.send(content)
							)
						)

					if @hasPackageStyles(pckg.name)
						_path = base + path.relative(@basePath, pckg.style.out)
						app.get(_path, (req, res) =>
							@buildStyles(pckg.name).then( (content) ->
								res.setHeader('Content-Type', 'text/css')
								res.send(content)
							)
						)
				)(pckg)

		app.listen(config.server.port)
		console.log 'Listening on port ' + config.server.port###


	build: ->
		@emit('build', @simq)
		return @simq.buildToFiles()


	watch: ->
		@build()

		ignore = new Array
		for name, pckg of @simq.packages
			if pckg.application != null then ignore.push(pckg.application)
			if pckg.style != null then ignore.push(pckg.style.out)

		watch.watchTree(@simq.basePath, {},  (file, curr, prev) =>
			if typeof file == 'string' && file.match(/~$/) == null && file.match(/^\./) == null && ignore.indexOf(path.resolve(file)) == -1		# filter in option is not working...
				@build()
		)


	create: (name) ->
		if !name
			throw new Error 'Please enter name of new application.'

		_path = path.resolve(name)

		if fs.existsSync(_path)
			throw new Error 'Directory with ' + name + ' name is already exists.'

		ncp.ncp(path.normalize(__dirname + '/../sandbox'), _path, (err) ->
			if err
				throw new Error 'There is some error with creating new application.'
		)


	clean: (cacheDirectory = null) ->
		for name, pckg in @simq.packages
			if pckg.application != null && fs.existsSync(pckg.application)
				fs.unlinkSync(pckg.application)

			if pckg.style != null && fs.existsSync(pckg.style.out)
				fs.unlinkSync(pckg.style.out)

			if cacheDirectory != null
				_path = path.resolve(cacheDirectory + '/__' + Compiler.CACHE_NAMESPACE + '.json')
				if fs.existsSync(_path)
					fs.unlinkSync(_path)



module.exports = Commands