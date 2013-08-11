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


	parseApplication: (section, name) ->
		return (new Application(@simq, @loader, @basePath, section, name)).parse()


	parseStyle: (path, name) ->
		return (new Style(@loader)).parse(path, @config.packages[name])


module.exports = Parser