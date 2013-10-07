Q = require 'q'
required = require 'flatten-required'
Info = require 'module-info'
Compiler = require 'source-compiler'
path = require 'path'
fs = require 'fs'

Package = require './Package'
Helpers = require '../Helpers'

class Builder extends Package


	pckg: null

	autoModule: ['.json', '.eco']


	constructor: (@pckg) ->
		if @pckg !instanceof Package
			throw new Error 'Package must be an instance of Package/Package'


	build: ->
		deferred = Q.defer()

		Q.all([
			@buildModules()
			@buildAutorun()
		])

		return deferred.promise


	buildModules: ->
		deferred = Q.defer()

		@prepareModules().then( (modules) =>
			c = [@loadMain()]

			for name, _path of modules
				c.push(@compileModule(name, _path))

			Q.all(c).then( (data) ->
				main = data.shift()
				deferred.resolve("#{main}({\n#{data}\n});")
			).fail( (err) ->
				deferred.reject(err)
			)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	buildAutorun: ->
		deferred = Q.defer()

		deferred.resolve('')

		return deferred.promise


	prepareModules: ->
		deferred = Q.defer()

		paths = []
		for _path in @pckg.modules
			paths.push(_path)

		required.findMany(paths, true, require('../../data.json').supportedCores).then( (data) ->
			result = {}

			for file in data.files
				info = Info.fromFile(file)
				result[info.getModuleName(file)] = file

			for name, _path in data.core
				if _path != null
					result[name] = _path

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	compileModule: (name, _path) ->
		deferred = Q.defer()

		Compiler.compileFile(_path).then( (result) =>
			type = path.extname(_path)

			if @autoModule.indexOf(type) != -1
				result = "module.exports = #{result}"

			if result != ''
				result = '\n\n\t/** code **/\n\t' + result.replace(/\n/g, '\n\t') + '\n'

			globals = '\t' + Helpers.getGlobalsForModule(name).join('\n').replace(/\n/g, '\n\t')
			result = "'#{name}': function(exports, __require, module) {\n\t/** node globals **/\n#{globals}#{result}\n}"

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadMain: ->
		deferred = Q.defer()

		_path = path.resolve(__dirname + '/../_Module.js')
		fs.readFile(_path, encoding: 'utf8', (err, data) ->
			if err
				deferred.reject(err)
			else
				data = data.replace(/\s+$/, '').replace(/;$/, '')
				deferred.resolve(data)
		)

		return deferred.promise


module.exports = Builder