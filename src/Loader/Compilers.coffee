coffee = require 'coffee-script'
eco = require 'eco'
less = require 'less'
Q = require 'q'
path = require 'path'
stylus = require 'stylus'

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
			@[ext + 'Loader'](content, file).then( (content) ->
				deferred.resolve(content.replace(/^\s+|\s+$/g, ''))
			, (e) ->
				deferred.reject(e)
			)
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


	coffeeLoader: (content, file) ->
		deferred = Q.defer()

		try
			deferred.resolve(coffee.compile(content, filename: file, literate: false))
		catch e
			deferred.reject(e)

		return deferred.promise

	ecoLoader: (content) -> return Q.resolve(eco.precompile(content))

	lessLoader: (content, file) ->
		deferred = Q.defer()
		debug = @simq.config.load().debugger

		options =
			paths: [path.dirname(file)]
			optimization: 1
			filename: file
			rootpath: ''
			relativeUrls: false
			strictImports: false
			compress: !debug.styles

		if debug.styles && debug.sourceMap then options.dumpLineNumbers = 'mediaquery'

		try
			less.render(content, options, (e, content) =>
				if e then deferred.reject(@parseLessError(e)) else deferred.resolve(content)
			)
		catch e
			deferred.reject(@parseLessError(e))

		return deferred.promise

	stylLoader: (content, file) ->
		deferred = Q.defer()

		stylus(content)
			.include(path.dirname(file))
			.set('include css', ('--includeCss' in process.argv))
			.set('compress', !@simq.config.load().debugger.styles)
			.render( (e, content) =>
				if e then deferred.reject(@parseStylusError(e, file)) else deferred.resolve(content)
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


	parseLessError: (e) ->
		err = new Error e.type + 'Error: ' + e.message.replace(/[\s\.]+$/, '') + ' in ' + e.filename + ':' + e.line + ':' + e.column
		err.type = e.type
		err.filename = e.filename
		err.line = e.line
		err.column = e.column

		return err


	parseStylusError: (e, file) ->
		data = e.message.split('\n')
		line = data[0].split(':')[1]
		message = data[data.length - 2]

		err = new Error message + ' in '  + file + ':' + line
		err.type = e.name
		err.filename = file
		err.line = line

		return err


module.exports = Compilers