expect = require('chai').expect
path = require 'path'
Finder = require 'fs-finder'
rimraf = require 'rimraf'

SimQ = require '../../lib/_SimQ'
Commands = require '../../lib/Commands'

dir = path.resolve(__dirname + '/..')

simq = null
commands = null

describe 'Commands', ->

	beforeEach( ->
		simq = new SimQ(dir)
		commands = new Commands(simq)
	)

	describe '#create()', ->
		it 'should throw an error if path already exists', (done) ->
			commands.create('data').fail( (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal('Directory data already exists.')
				done()
			).done()

		it 'should create new project from sandbox', (done) ->
			commands.create('test').then( ->
				files = Finder.findFiles(dir + '/test/*')
				expect(files).to.be.eql([
					dir + '/test/config/setup.json'
					dir + '/test/css/style.less'
					dir + '/test/public/application.js'
					dir + '/test/public/index.html'
				])
				rimraf(dir + '/test', -> done())
			).done()

	#describe '#clean()', ->
	#	it 'should remove all files created by simq', ->
	#		simq = new SimQ(dir + '/')