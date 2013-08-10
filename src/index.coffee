SimQ = require './SimQ'
optimist = require 'optimist'

argv = optimist.usage([
		'simq COMMAND'
		'	creare: create and prepare new application'
		'	server: create server'
		'	build:  save all changes to disk'
		'	watch:  watch for new changes and save them automatically to disk\n'
		'	--help: show this help'
	].join('\n'))
	.alias('c', 'config').describe('c', 'set custom config file')
	.alias('v', 'verbose').describe('v', 'make SimQ more talkative')
	.argv

argv.command = argv._[0]
argv.targets = argv._[1..]

if argv.help
	optimist.showHelp()

else if argv.command == 'create'
	SimQ.create(argv.targets[0])

else
	s = new SimQ(argv.config)
	s.v = !!argv.v

	switch argv.command
		when 'server'
			console.log 'Creating server'
			s.server()

		when 'build'
			console.log 'Building application'
			s.build()

		when 'watch'
			console.log 'Watching application'
			s.watch()

		else optimist.showHelp()