fs = require 'fs'
ncp = require 'ncp'
path = require 'path'
express = require 'express'
mime = require 'mime'
Compiler = require 'source-compiler'
Q = require 'q'
EventEmitter = require('events').EventEmitter

class Commands extends EventEmitter


	simq: null


	constructor: (@simq) ->


	server: (prefix = null, main = './public/index.html', routes = {}, port = 3000) ->
		app = express()
		base = if prefix == null then '/' else '/' + prefix

		main = path.join(@simq.basePath, main)
		if fs.existsSync(main)
			app.get(base, (req, res) ->
				res.setHeader('Content-Type', 'text/html')
				res.sendfile(main)
			)

		for route, _path of routes
			route = path.normalize(base + '/./' + route)
			_path = path.resolve(@simq.basePath + '/' + _path)
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

		for name, pckg of @simq.packages
			if pckg.skip == false
				pckg.name = name
				((pckg) =>
					if pckg.application != null
						_path = path.relative(@simq.basePath, pckg.application)
						_path = path.normalize(base + '/./' + _path)
						app.get(_path, (req, res) =>
							@simq.buildPackage(pckg.name).then( (data) ->
								res.setHeader('Content-Type', 'application/javascript')
								res.send(data.js)
							).fail( (err) -> throw err).done()
						)

					if pckg.style != null
						_path = path.relative(@simq.basePath, pckg.style.out)
						_path = path.normalize(base + '/./' + _path)
						app.get(_path, (req, res) =>
							@simq.buildPackage(pckg.name).then( (data) ->
								res.setHeader('Content-Type', 'text/css')
								res.send(data.css)
							).fail( (err) -> throw err).done()
						)
				)(pckg)

		return app.listen(port)


	build: ->
		@emit('build', @simq)
		return @simq.buildToFiles()


	watch: ->
		@build().fail( (err) -> throw err).done()

		ignore = new Array
		for name, pckg of @simq.packages
			if pckg.application != null then ignore.push(pckg.application)
			if pckg.style != null then ignore.push(pckg.style.out)

		watch.watchTree(@simq.basePath, {},  (file, curr, prev) =>
			if typeof file == 'string' && file.match(/~$/) == null && file.match(/^\./) == null && ignore.indexOf(path.resolve(file)) == -1		# filter in option is not working...
				console.log file
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
				deferred.resolve()
		)
		return deferred.promise


	clean: (cacheDirectory = null) ->
		for name, pckg of @simq.packages
			if pckg.application != null && fs.existsSync(pckg.application)
				fs.unlinkSync(pckg.application)

			if pckg.style != null && fs.existsSync(pckg.style.out)
				fs.unlinkSync(pckg.style.out)

			if cacheDirectory != null
				_path = path.join(@simq.basePath, cacheDirectory + '/__' + Compiler.CACHE_NAMESPACE + '.json')
				if fs.existsSync(_path)
					fs.unlinkSync(_path)



module.exports = Commands