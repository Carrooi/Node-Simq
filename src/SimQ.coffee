fs = require 'fs'
watch = require 'watch'
_path = require 'path'
Loader = require './Loader'
Parser = require './Parser'

class SimQ


	basePath: '.'

	config: null

	configPath: 'setup.json'

	debug: false

	parser: null


	constructor: ->
		@parser = new Parser(@, new Loader(@), @basePath)


	build: ->
		config = @getConfig()

		for name, pckg of config.packages
			if pckg.application
				fs.writeFileSync(@basePath + '/' + pckg.application, @parser.parseApplication(pckg))

			if pckg.style && pckg.style.in && pckg.style.out
				((pckg) =>
					@parser.parseStyles(pckg.style.in, (content) =>
						fs.writeFileSync(@basePath + '/' + pckg.style.out, content)
					)
				)(pckg)

		return @


	watch: ->
		@build()

		watch.watchTree(@basePath, { persistent: true, interval: 1000 },  (file, curr, prev) =>
			@build() if curr and (curr.nlink is 0 or +curr.mtime isnt +prev?.mtime)
		)

		return @


	getModuleName: (path) ->
		path = _path.normalize(path)
		return path.replace(new RegExp(_path.extname(path) + '$'), '')


	getConfig: ->
		if @config == null
			if not fs.existsSync(@basePath + '/' + @configPath)
				throw new Error 'Config file setup.json was not found.'

			@config = JSON.parse(fs.readFileSync(@basePath + '/' + @configPath))

			if @config.main		# back compatibility
				@config.application = @config.main
				delete @config.main

			if !@config.packages
				newConfig =
					packages:
						__main__: @config
				@config = newConfig

		return @config


module.exports = SimQ