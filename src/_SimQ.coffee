Q = require 'q'
fs = require 'fs'

Package = require './Package/Package'
Builder = require './Package/Builder'

class SimQ


	packages: null

	basePath: null

	jquerify: false


	constructor: (@basePath) ->
		@packages = {}


	release: ->
		@packages = {}
		@jquerify = false


	hasPackage: (name) ->
		return typeof @packages[name] != 'undefined'


	addPackage: (name, pckg = null) ->
		if @hasPackage(name)
			throw new Error 'Package ' + name + ' is already registered.'

		if pckg == null
			@packages[name] = new Package(@basePath)
		else
			if pckg !instanceof Package
				throw new Error 'Package ' + name + ' must be an instance of Package/Package.'

			@packages[name] = pckg

		return @packages[name]


	getPackage: (name) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		return @packages[name]


	removePackage: (name) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		delete @packages[name]
		return @


	buildPackage: (name) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		builder = new Builder(@packages[name])
		builder.jquerify = @jquerify

		return builder.build()


	buildPackageToFile: (name) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		deferred = Q.defer()

		@buildPackage(name).then( (data) =>
			if data.js != null
				fs.writeFileSync(@packages[name].application, data.js)

			if data.css != null
				fs.writeFileSync(@packages[name].style.out, data.css)

			deferred.resolve(data)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	build: ->
		deferred = Q.defer()

		result = []
		for name, pckg of @packages
			result.push(@buildPackage(name))

		Q.all(result).then( (data) =>
			result = {}
			count = 0
			for name, pckg of @packages
				result[name] = data[count]
				count++

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	buildToFiles: ->
		deferred = Q.defer()

		result = []
		for name, pckg of @packages
			if pckg.application != null
				result.push(@buildPackageToFile(name))

		Q.all(result).then( (data) =>
			result = {}
			count = 0
			for name, pckg of @packages
				result[name] = data[count]
				count++

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


module.exports = SimQ