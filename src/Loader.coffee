Q = require 'q'
path = require 'path'
Compiler = require 'source-compiler'
Package = require './Package'

class Loader


	jquerify: false

	modulesAllowed: ['js', 'json', 'coffee', 'ts', 'eco']


	loadFile: (_path, dependents = null) ->
		options =
			precompile: true
			jquerify: @jquerify

		if dependents != null
			options.dependents = dependents

		return Compiler.compileFile(_path, options)


	loadFiles: (paths) ->
		result = []
		for _path in paths
			result.push(@loadFile(_path))

		return Q.all(result)


	loadModule: (_path, base = null) ->
		if Compiler.getType(_path) !in @modulesAllowed
			return Q.reject(new Error "File #{_path} is not module")

		if _path.match(/^http/) != null
			return Q.reject(new Error "Remote file #{_path} can not be used as module")

		_path = path.resolve(_path)
		deferred = Q.defer()

		@loadFile(_path).then( (data) =>
			name = _path.replace(new RegExp('^' + process.cwd() + '\/'), '')
			if base != null then name = name.replace(new RegExp('^' + base + '/'), '')

			globals = Package.getGlobalsForModule(name).join('\n')
			deferred.resolve("'#{name}': function(exports, __require, module) {\n#{globals}\n#{data}\n}")
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadModules: (paths, base = null) ->
		result = []
		for _path in paths
			result.push(@loadModule(_path, base))

		return Q.all(result)


module.exports = Loader