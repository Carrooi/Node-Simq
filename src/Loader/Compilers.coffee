coffee = require 'coffee-script'
eco = require 'eco'
less = require 'less'
Q = require 'q'
path = require 'path'

class Compilers


	simq: null


	constructor: (@simq) ->


	hasLoader: (ext) ->
		ext = ext.toLowerCase()
		return typeof @[ext + 'Loader'] != 'undefined'


	prepare: (file, content) ->
		deferred = Q.defer()
		file = path.resolve(file)
		ext = path.extname(file).substr(1).toLowerCase()

		if @hasLoader(ext)
			@[ext + 'Loader'](content, file).then( (content) -> deferred.resolve(content.replace(/^\s+|\s+$/g, '')) )
		else
			deferred.resolve(content.replace(/^\s+|\s+$/g, ''))
		return deferred.promise


	hasCompiler: (ext) ->
		ext = ext.toLowerCase()
		return typeof @[ext + 'Compiler'] != 'undefined'


	compile: (file, content) ->
		deferred = Q.defer()
		file = path.resolve(file)
		ext = path.extname(file).substr(1).toLowerCase()

		if !@hasCompiler(ext) then throw new Error 'File type ' + ext + ' is not supported.'

		@[ext + 'Compiler'](content, file).then( (content) -> deferred.resolve(content) )
		return deferred.promise


	coffeeLoader: (content) -> return Q.resolve(coffee.compile(content))

	ecoLoader: (content) -> return Q.resolve(eco.precompile(content))

	lessLoader: (content, file) ->
		deferred = Q.defer()

		options =
			paths: [path.dirname(file)]
			optimization: 1
			filename: file
			rootpath: ''
			relativeUrls: false
			strictImports: false
			compress: !@simq.config.load().debugger.styles

		less.render(content, options, (e, content) ->
			if e then deferred.reject(e) else deferred.resolve(content)
		)

		return deferred.promise


	jsCompiler: (content) -> return Q.resolve('return (function() {\n' + content + '\n\t\t}).call(this);')

	coffeeCompiler: (content) -> return Q.resolve('return ' + content)

	jsonCompiler: (content) -> return Q.resolve('module.exports = ' + content)

	ecoCompiler: (content) ->
		if @simq.config.load().template.jquerify == true
			module =			# this snippet of code is from spine/hem package
				"""
				module.exports = function (values, data) {
					var $  = jQuery, result = $();
					values = $.makeArray(values);
					data = data || {};
					for (var i=0; i < values.length; i++) {
						var value = $.extend({}, values[i], data, {index: i});
						var elem  = $((#{content})(value));
						elem.data('item', value);
						$.merge(result, elem);
					}
					return result;
				};
				"""
		else
			module = 'module.exports = ' + content

		return Q.resolve(module)


module.exports = Compilers