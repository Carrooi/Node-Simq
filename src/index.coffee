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

if argv.help
	optimist.showHelp()

else if argv.command == 'create'
	SimQ.create(argv.targets[0])

else
	debug = argv.debug and true or false

	s = new SimQ(debug, '.', argv.config)

	switch argv.command
		when 'build'
			console.log 'Building application'
			s.build()

		when 'watch'
			console.log 'Watching application'
			s.watch()

		else optimist.showHelp()