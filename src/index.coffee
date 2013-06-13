SimQ = require './SimQ'
optimist = require 'optimist'

argv = optimist.usage([
		'simq COMMAND'
		'	creare: create and prepare new application'
		'	build:  save all changes to disk'
		'	watch:  watch for new changes and save them automatically to disk\n'
		'	--help: show this help'
	].join('\n'))
	.alias('d', 'debug').describe('d', 'all compilations use debug mode')
	.alias('c', 'config').describe('c', 'set custom config file')
	.argv

argv.command = argv._[0]
argv.targets = argv._[1..]

s = new SimQ

s.debug = argv.debug and true or false

if argv.config
	s.configPath = argv.config
	s.config.path = argv.config

if argv.help
	optimist.showHelp()
	process.exit()

switch argv.command
	when 'build' then s.build()
	when 'watch' then s.watch()
	when 'create' then s.create(argv.targets[0])
	else
		optimist.showHelp()
		process.exit()