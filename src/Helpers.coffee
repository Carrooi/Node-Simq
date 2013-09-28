Finder = require 'fs-finder'
fs = require 'fs'
path = require 'path'

class Helpers


	@expandFilesList: (paths, basePath = null) ->
		result = []
		for _path in paths
			if _path.match(/^http/) == null
				if basePath != null
					_path = basePath + '/' + _path

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


module.exports = Helpers