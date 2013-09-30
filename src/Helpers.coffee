Finder = require 'fs-finder'
Module = require 'module'
fs = require 'fs'
path = require 'path'

class Helpers


	@supportedCores: null


	@expandFilesList: (paths, basePath = null, base = null) ->
		result = []
		for _path in paths
			if _path.match(/^http/) == null
				if basePath != null
					_path = basePath + '/' + (if base == null then '' else base) + _path

				_path = path.resolve(_path)

				if fs.existsSync(_path) && fs.statSync(_path).isFile()
					result.push(_path)
				else
					result = result.concat(Finder.findFiles(_path))
			else
				result.push(_path)

		return @removeDuplicates(result)


	@removeDuplicates: (array) ->
		return array.filter( (el, pos) -> return array.indexOf(el) == pos)


	@getGlobalsForModule: (name) ->
		dir = path.dirname(name)

		globals =
			require: "function(name) {return __require(name, '#{name}');}"
			__filename: "'#{name}'"
			__dirname: "'#{dir}'"
			process: "{cwd: function() {return '/';}, argv: ['node', '#{name}'], env: {}}"

		result = []
		for key, value of globals
			result.push("var #{key} = #{value};")

		return result


	@resolvePath: (basePath, _path, base = null) ->
		_path = basePath + '/' + (if base == null then '' else base) + _path
		return path.resolve(_path)


	@isCoreModuleSupported: (name) ->
		if @supportedCores == null
			@supportedCores = require('../data.json').supportedCores

		return @supportedCores.indexOf(name) != -1


	@getCoreModulesPaths: ->
		return Module.globalPaths


	@getCoreModulePath: (name) ->
		for dir in @getCoreModulesPaths()
			_path = "#{dir}/#{name}.js"
			if fs.existsSync(_path) && fs.statSync(_path).isFile()
				return _path

		return null



module.exports = Helpers