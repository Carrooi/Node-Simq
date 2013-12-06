fs = require 'fs'
ncp = require 'ncp'
path = require 'path'
express = require 'express'
mime = require 'mime'
Compiler = require 'source-compiler'
Q = require 'q'
watch = require 'watch'
Finder = require 'fs-finder'
EventEmitter = require('events').EventEmitter

class Commands extends EventEmitter


	simq: null

	logger: null


	constructor: (@simq) ->


	log: (message) ->
		if @logger != null
			return @logger.log(message)

		return message


	server: (prefix = null, main = './public/index.html', routes = {}, port = 3000) ->
		@log 'Creating server on port ' + port

		app = express()
		base = if prefix == null then '/' else '/' + prefix

		main = path.join(@simq.basePath, main)
		if fs.existsSync(main)
			@log 'Mapping ' + base + ' to ' + main
			app.get(base, (req, res) ->
				res.setHeader('Content-Type', 'text/html')
				res.sendfile(main)
			)

		for route, _path of routes
			route = path.normalize(base + '/./' + route)
			_path = path.resolve(@simq.basePath + '/' + _path)
			data = {route: route, path: _path}

			if fs.statSync(_path).isDirectory()
				@log 'Mapping ' + route + ' to directory ' + _path
				app.use(route, express.static(_path))
			else
				((data) =>
					@log 'Mapping ' + data.route + ' to ' + data.path
					app.get(data.route, (req, res) ->
						res.setHeader('Content-Type', mime.lookup(data.path))
						res.sendfile(data.path)
					)
				)(data)

		@emit 'build', @simq

		for name, pckg of @simq.packages
			if pckg.skip == false
				pckg.name = name
				((pckg) =>
					if pckg.target != null
						_path = path.relative(@simq.basePath, pckg.target)
						_path = path.normalize(base + '/./' + _path)
						@log 'Mapping ' + _path + ' to ' + pckg.name + ' package'
						app.get(_path, (req, res) =>
							@simq.buildPackage(pckg.name).then( (data) ->
								res.setHeader('Content-Type', 'application/javascript')
								res.send(data.js)
							).fail( (err) -> throw err).done()
						)

					if pckg.style != null
						_path = path.relative(@simq.basePath, pckg.style.out)
						_path = path.normalize(base + '/./' + _path)
						@log 'Mapping ' + _path + ' to ' + pckg.name + ' package styles'
						app.get(_path, (req, res) =>
							@simq.buildPackage(pckg.name).then( (data) ->
								res.setHeader('Content-Type', 'text/css')
								res.send(data.css)
							).fail( (err) -> throw err).done()
						)
				)(pckg)

		@log 'Listening on port ' + port

		return app.listen(port)


	build: ->
		@log 'Building application'
		@emit('build', @simq)
		return @simq.buildToFiles()


	watch: ->
		@log 'Watching application'
		@build().fail( (err) -> throw err).done()

		ignore = new Array
		for name, pckg of @simq.packages
			if pckg.target != null then ignore.push(pckg.target)
			if pckg.style != null then ignore.push(pckg.style.out)

		watch.watchTree(@simq.basePath, {},  (file, curr, prev) =>
			if typeof file == 'string' && file.match(/~$/) == null && file.match(/^\./) == null && ignore.indexOf(path.resolve(file)) == -1		# filter in option is not working...
				@log 'Rebuilding from ' + file
				@build().fail( (err) -> throw err).done()
		)


	create: (name) ->
		if !name
			return Q.reject(new Error 'Please enter name of new application.')

		_path = path.resolve(@simq.basePath + '/' + name)

		if fs.existsSync(_path)
			return Q.reject(new Error 'Directory ' + name + ' already exists.')

		deferred = Q.defer()
		ncp.ncp(path.normalize(__dirname + '/../sandbox'), _path, (err) ->
			if err
				deferred.reject(new Error 'There is some error with creating new application.')
			else
				files = Finder.from(_path).showSystemFiles().findFiles('.<gitkeep|gitignore>')
				for file in files
					fs.unlinkSync(file)

				deferred.resolve()
		)
		return deferred.promise


	clean: (cacheDirectory = null) ->
		@log 'Cleaning packages'
		for name, pckg of @simq.packages
			if pckg.target != null && fs.existsSync(pckg.target)
				@log 'Removing ' + pckg.target
				fs.unlinkSync(pckg.target)

			if pckg.style != null && fs.existsSync(pckg.style.out)
				@log 'Removing ' + pckg.style.out
				fs.unlinkSync(pckg.style.out)

			if cacheDirectory != null
				_path = path.join(@simq.basePath, cacheDirectory + '/__' + Compiler.CACHE_NAMESPACE + '.json')
				if fs.existsSync(_path)
					@log 'Removing cache in ' + _path
					fs.unlinkSync(_path)



module.exports = Commands