Q = require 'q'
path = require 'path'
Compiler = require 'source-compiler'

class Loader


	pckg: null

	jquerify: false

	modulesAllowed: ['js', 'json', 'coffee', 'ts', 'eco']

	autoModule: ['json', 'eco']


	constructor: (@pckg) ->


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


	loadModule: (_path, base = null, name = null) ->
		type = Compiler.getType(_path)

		if type !in @modulesAllowed
			return Q.reject(new Error "File #{_path} is not module")

		if _path.match(/^http/) != null
			return Q.reject(new Error "Remote file #{_path} can not be used as module")

		_path = path.resolve(_path)
		deferred = Q.defer()

		@loadFile(_path).then( (data) =>
			if name == null
				name = _path.replace(new RegExp('^' + process.cwd() + '\/'), '')
				name = name.replace(new RegExp('^' + base + '/'), '') if base != null
			else
				#console.log name

			globals = @pckg.getGlobalsForModule(name).join('\n')
			data = "module.exports = #{data}" if type in @autoModule
			deferred.resolve("'#{name}': function(exports, __require, module) {\n#{globals}\n#{data}\n}")
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadModules: (paths, base = null) ->
		result = []
		switch Object.prototype.toString.call(paths)
			when '[object Array]'
				for _path in paths
					result.push(@loadModule(_path, base))
			when '[object Object]'
				for name, _path of paths
					result.push(@loadModule(_path, base, name))

		return Q.all(result)


module.exports = Loader