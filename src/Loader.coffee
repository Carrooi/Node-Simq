Q = require 'q'
path = require 'path'
Compiler = require 'source-compiler'

class Loader


	minify:
		styles: true
		scripts: true

	jquerify: false

	types:
		less: 'style'
		scss: 'style'
		styl: 'style'
		js: 'script'
		json: 'script'
		coffee: 'script'
		ts: 'script'
		eco: 'script'

	modulesAllowed: ['js', 'json', 'coffee', 'ts', 'eco']


	loadFile: (_path, dependents = null) ->
		options =
			precompile: true
			minify: @minify[Compiler.getType(_path) + 's']
			jquerify: @jquerify

		if dependents != null
			options.dependents = dependents

		return Compiler.compileFile(_path, options)


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

			globals = Loader.getGlobalsForModule(name).join('\n')
			deferred.resolve("'#{name}': function(exports, __require, module) {\n#{globals}\n#{data}\n}")
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	@getGlobalsForModule: (name) ->
		globals =
			require: "function(name) {return __require(name, '#{name}');}"
			__filename: "'#{name}'"
			__dirname: '\'' + path.dirname(name) + '\''

		result = []
		for key, value of globals
			result.push("var #{key} = #{value};")

		return result


module.exports = Loader