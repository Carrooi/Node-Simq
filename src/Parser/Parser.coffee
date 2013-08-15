Q = require 'q'
Application = require './Application'
Style = require './Style'
Loader = require '../Loader'
Compiler = require 'source-compiler'

class Parser


	simq: null

	config: null

	loader: null

	basePath: null


	constructor: (@simq, @basePath) ->
		@config = @simq.config.load()
		@loader = new Loader
		@loader.jquerify = @config.template.jquerify

		if @config.cache.directory != null
			Compiler.setCache(@config.cache.directory)


	parseApplication: (section) ->
		basePath = if section.base == null then @basePath else @basePath + '/' + section.base

		application = new Application(@loader, basePath, section)
		application.minify = !@config.debugger.scripts

		return application.parse()


	parseStyle: (section) ->
		return (new Style(@loader, section)).parse()


module.exports = Parser