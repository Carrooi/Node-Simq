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


	parseApplication: (section, minify = true) ->
		return (new Application(@simq, @loader, @basePath)).parse(section, minify)


	parseStyle: (path, minify = true) ->
		return (new Style(@loader)).parse(path, minify)


module.exports = Parser