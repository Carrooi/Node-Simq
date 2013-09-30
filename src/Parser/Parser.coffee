Q = require 'q'
Application = require './Application'
Style = require './Style'
Loader = require '../Loader'
Compiler = require 'source-compiler'
path = require 'path'

class Parser


	simq: null

	pckg: null

	config: null

	loader: null

	basePath: null

	initialized: false


	constructor: (@simq, @pckg, @basePath) ->


	prepare: ->
		if !@initialized
			@config = @simq.config.load()
			@loader = new Loader(@pckg)
			@loader.jquerify = @config.template.jquerify

			if @config.cache.directory != null
				Compiler.setCache(@config.cache.directory)

			@initialized = true


	parseApplication: (section) ->
		@prepare()

		basePath = if section.base == null then @basePath else @basePath + '/' + section.base
		basePath = path.normalize(basePath)

		application = new Application(@loader, @pckg, basePath, section)
		application.v = @simq.v
		application.minify = !@config.debugger.scripts

		return application.parse()


	parseStyle: (section) ->
		@prepare()

		return (new Style(@loader, section)).parse()


module.exports = Parser