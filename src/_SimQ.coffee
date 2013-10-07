Package = require './Package/Package'

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


module.exports = SimQ