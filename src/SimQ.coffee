fs = require 'fs'
watch = require 'watch'
_path = require 'path'
ncp = require 'ncp'
Loader = require './Loader'
Parser = require './Parser'
Configurator = require './Config/Configurator'

class SimQ


	basePath: '.'

	configPath: 'setup.json'

	config: null

	debug: false

	parser: null


	constructor: ->
		@config = new Configurator(@basePath + '/config/' + @configPath)
		@parser = new Parser(@, new Loader(@), @basePath)


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


	create: (name) ->
		if !name then throw new Error 'Please enter name of new application.'

		path = _path.resolve(name)
		if fs.existsSync(path) then throw new Error 'Directory with ' + name + ' name is already exists.'

		ncp.ncp(__dirname + '/sandbox', path, (err) ->
			if err then throw new Error 'There is some error with creating new application.'
		)

		return @


	getModuleName: (path) ->
		path = _path.normalize(path)
		return path.replace(new RegExp(_path.extname(path) + '$'), '')


module.exports = SimQ