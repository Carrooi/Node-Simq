Q = require 'q'
Application = require './Application'
Style = require './Style'
Loader = require '../Loader/Loader'

class Parser


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @basePath) ->
		@loader = new Loader(@simq)

		cacheDirectory = @simq.config.load().cache.directory
		@loader.setCacheDirectory(cacheDirectory) if cacheDirectory != null


	parseApplication: (section, name) ->
		return (new Application(@simq, @loader, @basePath, section, name)).parse()


	parseStyle: (path, name) ->
		return (new Style(@loader)).parse(path, name)


module.exports = Parser