coffee = require 'coffee-script'
eco = require 'eco'

class Compilers


	simq: null


	constructor: (@simq) ->


	hasLoader: (name) ->
		return typeof @[name + 'Loader'] != 'undefined'


	prepare: (name, content) ->
		content = if @hasLoader(name) then @[name + 'Loader'](content) else content
		return content.replace(/^\s+|\s+$/g, '')


	hasCompiler: (name) ->
		return typeof @[name + 'Compiler'] != 'undefined'


	compile: (name, content) ->
		if !@hasCompiler(name) then throw new Error 'File type ' + name + ' is not supported.'
		return @[name + 'Compiler'](content)


	coffeeLoader: (content) -> return coffee.compile(content)

	ecoLoader: (content) -> return eco.precompile(content)


	jsCompiler: (content) -> return 'return ' + content

	coffeeCompiler: (content) -> return 'return ' + content

	jsonCompiler: (content) -> return 'module.exports = ' + content

	ecoCompiler: (content) ->
		module = 'module.exports = ' + content

		if @simq.config.load().template.jquerify == true
			module =			# this snippet of code is from spine/hem package
				"""
				module.exports = function (values, data) {
					var $  = jQuery, result = $();
					values = $.makeArray(values);
					data = data || {};
					for (var i=0; i < values.length; i++) {
						var value = $.extend({}, values[i], data, {index: i});
						var elem  = $((#{module})(value));
						elem.data('item', value);
						$.merge(result, elem);
					}
					return result;
				};
				"""

		return module


module.exports = Compilers