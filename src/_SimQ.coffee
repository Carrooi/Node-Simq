Q = require 'q'
fs = require 'fs'

Package = require './Package/Package'
Builder = require './Package/Builder'

class SimQ


	packages: null

	basePath: null


	constructor: (@basePath) ->
		@packages = {}


	hasPackage: (name) ->
		return typeof @packages[name] != 'undefined'


	addPackage: (name) ->
		if @hasPackage(name)
			throw new Error 'Package ' + name + ' is already registered.'

		@packages[name] = new Package(@basePath)

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

		return (new Builder(@packages[name])).build()


	buildPackageToFile: (name, file) ->
		if !@hasPackage(name)
			throw new Error 'Package ' + name + ' is not registered.'

		deferred = Q.defer()

		@buildPackage(name).then( (data) ->
			fs.writeFileSync(file, data)
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
				result.push(@buildPackageToFile(name, pckg.application))

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