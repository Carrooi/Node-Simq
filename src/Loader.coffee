_path = require 'path'
fs = require 'fs'
coffee = require 'coffee-script'
eco = require 'eco'

class Loader


	simq: null


	constructor: (@simq) ->


	loadFile: (path) ->
		path = _path.resolve(path)
		ext = _path.extname(path).substring(1).toLowerCase()

		if typeof @loaders[ext] == 'undefined'
			throw new Error 'File .' + ext + ' is not supported'

		file = fs.readFileSync(path, 'utf8').toString()

		try
			file = @loaders[ext](file)
		catch e
			throw new Error(e.toString() + ' in ' + path)

		file = @normalize(file)

		return file


	loadModule: (path, base = null) ->
		path = _path.normalize(path)
		ext = _path.extname(path).substring(1).toLowerCase()

		if typeof @compilers[ext] == 'undefined'
			throw new Error 'Module of type ' + ext + ' is not supported'

		lib = @loadFile(path).replace(/\n/g, '\n\t\t')
		name = @simq.getModuleName(path)

		if base != null then name = name.replace(new RegExp('^' + base + '/'), '')

		lib = @compilers[ext](lib)

		# todo: move to own compiler
		# this snippet of code is from spine/hem package
		if ext == 'eco' && @simq.config.load().template.jquerify == true
			lib =
				"""
				module.exports = function (values, data) {
					var $  = jQuery, result = $();
					values = $.makeArray(values);
					data = data || {};
					for (var i=0; i < values.length; i++) {
						var value = $.extend({}, values[i], data, {index: i});
						var elem  = $((#{lib})(value));
						elem.data('item', value);
						$.merge(result, elem);
					}
					return result;
				};
				"""

		return '\'' + name + '\': function(exports, require, module) {\n\t\t' + lib + '\n\t}'


	loadModules: (dir, type = null, base = null) ->
		dir = _path.normalize(dir)

		files = fs.readdirSync(dir)
		result = new Array

		for name in files
			name = dir + name
			stats = fs.statSync(name)

			if stats.isFile() && name.substring(name.length - 1) != '~'
				if type
					continue if _path.extname(name).toLowerCase() != '.' + type

				result.push(@loadModule(name, base))
			else if stats.isDirectory()
				result = result.concat(@loadModules(name + '/', type, base))

		return result


	normalize: (content) ->
		content = content.replace(/^\s+|\s+$/g, '')
		return content


	loaders:
		js: (content) -> return content
		coffee: (content) -> return coffee.compile(content)
		json: (content) -> return content
		eco: (content) -> return eco.precompile(content)


	compilers:
		js: (content) -> return 'return ' + content
		coffee: (content) -> return 'return ' + content
		json: (content) -> return 'module.exports = ' + content
		eco: (content) -> return 'module.exports = ' + content


module.exports = Loader