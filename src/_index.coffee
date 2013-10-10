optimist = require 'optimist'

SimQ = require './lib/_SimQ'

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

