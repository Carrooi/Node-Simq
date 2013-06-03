fs = require 'fs'

class Config


	path: ''

	data: null

	defaults:
		packages: {}

	defaultsPackage:
		include: null
		application: null
		style:
			in: null
			out: null
		modules: []
		aliases: {}
		run: []
		libs:
			begin: {}
			end: {}



	constructor: (@path) ->


	load: ->
		if @data == null
			if not fs.existsSync(@path)
				throw new Error 'Config file ' + @path + ' was not found.'

			@data = JSON.parse(fs.readFileSync(@path))

			if @data.main		# back compatibility
				@data.application = @data.main
				delete @data.main

			if !@data.packages
				config =
					packages:
						__main__: @data
				@data = config

		return @data


module.exports = Config