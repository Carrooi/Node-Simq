Application = require './Application'
Style = require './Style'
Q = require 'q'

class Parser


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @loader, @basePath) ->


	parseApplication: (section, minify = true) ->
		return (new Application(@simq, @loader, @basePath)).parse(section, minify)


	parseStyle: (path, minify = true) ->
		return (new Style(@basePath)).parse(path, minify)


module.exports = Parser