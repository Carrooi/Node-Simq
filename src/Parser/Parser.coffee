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


	parseApplication: (section, name) ->
		return (new Application(@simq, @loader, @basePath)).parse(section, name)


	parseStyle: (path, name) ->
		return (new Style(@loader)).parse(path, name)


module.exports = Parser