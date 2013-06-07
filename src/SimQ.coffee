fs = require 'fs'
watch = require 'watch'
_path = require 'path'
Loader = require './Loader'
Parser = require './Parser'
Config = require './Config'

class SimQ


	basePath: '.'

	config: null

	configPath: 'setup.json'

	debug: false

	parser: null


	constructor: ->
		@parser = new Parser(@, new Loader(@), @basePath)
		@config = new Config(@basePath + '/' + @configPath)


	build: ->
		config = @config.load()

		for name, pckg of config.packages
			if pckg.application
				fs.writeFileSync(@basePath + '/' + pckg.application, @parser.parseApplication(pckg, !@debug))

			if pckg.style && pckg.style.in && pckg.style.out
				((pckg) =>
					@parser.parseStyles(pckg.style.in, !@debug, (content) =>
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


module.exports = SimQ