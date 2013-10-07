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
				expect(data).to.have.string("'package/modules/2.js'")
				expect(data).to.have.string("'package/modules/3.js'")
				expect(data).to.have.string("'module'")
				done()
			).done()

	describe '#buildAutorun()', ->
		it 'should build autorun section', (done) ->
			pckg.addModule('./modules/1.js')
			pckg.addToAutorun('modules/1')
			pckg.addToAutorun('libs/begin/4.js')
			builder.buildAutorun().then( (data) ->
				expect(data).to.be.equal([
					"require('modules/1.js');"
					'// 4'
				].join('\n'))
				done()
			).done()