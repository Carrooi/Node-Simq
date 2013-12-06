optimist = require 'optimist'
path = require 'path'
Compiler = require 'source-compiler'

SimQ = require './SimQ'
Commands = require './Commands'
Configurator = require './Config/Configurator'
Factory = require './Package/Factory'
Logger = require './Logger'

argv = optimist.usage([
	'simq COMMAND'
	'	creare: create and prepare new application'
	'	server: create server'
	'	build:  save all changes to disk'
	'	watch:  watch for new changes and save them automatically to disk'
	'	clean:  remove all files created by simq\n'
	'	--help: show this help'
].join('\n'))
.alias('c', 'config').describe('c', 'set custom config file')
.argv

argv.command = argv._[0]
argv.targets = argv._[1..]

basePath = process.cwd()
cacheDirectory = null

simq = new SimQ(basePath)
commands = new Commands(simq)

if argv.command in ['server', 'build', 'watch']
	configPath = basePath + '/' + (if argv.c then argv.c else './config/setup.json')
	configPath = path.resolve(configPath)

	configurator = new Configurator(configPath)
	config = configurator.load()

	logger = new Logger(if config.debugger.log != false then config.debugger.log else null)

	simq.logger = logger
	commands.logger = logger

	commands.on 'build', (simq) ->
		configurator.invalidate()
		config = configurator.load()

		cacheDirectory = config.cache.directory
		if cacheDirectory != null
			cacheDirectory = path.resolve(basePath, cacheDirectory)
			Compiler.setCache(cacheDirectory)
		else
			Compiler.cache = null

		simq.release()
		simq.jquerify = config.template.jquerify
		simq.minify = config.debugger.minify
		simq.stats = config.debugger.filesStats

		for name, pckg of config.packages
			pckg = Factory.create(basePath, pckg)
			simq.addPackage(name, pckg)

promise = null
switch argv.command
	when 'create' then promise = commands.create(argv.targets[0])
	when 'server' then commands.server(config.routes.prefix, config.routes.main, config.routes.routes, config.server.port)
	when 'build' then promise = commands.build()
	when 'watch' then commands.watch()
	when 'clean' then commands.clean(cacheDirectory)
	else optimist.showHelp()

if promise != null
	promise.fail( (err) ->
		file = if typeof err.filename != 'undefined' && err.filename != null then err.filename else null
		line = if typeof err.line != 'undefined' && err.line != null then err.line else null

		if file != null
			err.message += ' in ' + file

		if line != null
			err.message += ':' + line

		throw err
	).done()