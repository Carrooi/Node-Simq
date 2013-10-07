expect = require('chai').expect
path = require 'path'
Info = require 'module-info'

Package = require '../../../lib/Package/Package'
Builder = require '../../../lib/Package/Builder'

dir = path.resolve(__dirname + '/../../data/package')
pckg = null
builder = null

describe 'Package/Builder', ->

	beforeEach( ->
		pckg = new Package(dir)
		builder = new Builder(pckg)
	)

	describe '#buildModules()', ->
		it 'should build one module from absolute path', (done) ->
			pckg.addModule(dir + '/modules/1.js')
			builder.buildModules().then( (data) ->
				done()
			).done()