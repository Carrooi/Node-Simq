optimist = require 'optimist'
path = require 'path'

SimQ = require './lib/_SimQ'
Commands = require './lib/Commands'
Configurator = require './lib/_Config/Configurator'
Factory = require './lib/Package/Factory'

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
.alias('v', 'verbose').describe('v', 'make SimQ more talkative')
.argv

argv.command = argv._[0]
argv.targets = argv._[1..]

basePath = process.cwd()

simq = new SimQ(basePath)
commands = new Commands(simq)

if argv.command in ['server', 'build', 'watch']
	configPath = basePath + '/' + (if argv.c then argv.c else './config/setup.json')
	configPath = path.resolve(configPath)

	config = new Configurator(configPath)
	config = config.load()

	for name, pckg of config.packages
		pckg = Factory.create(basePath, pckg)
		simq.addPackage(name, pckg)

switch argv.command
	when 'create' then commands.create(argv.targets[0])
	when 'server' then commands.server()
	when 'build' then commands.build()
	when 'watch' then commands.watch()
	else optimist.showHelp()