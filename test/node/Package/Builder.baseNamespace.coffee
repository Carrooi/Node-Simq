expect = require('chai').expect
path = require 'path'
Info = require 'module-info'

Package = require '../../../lib/Package/Package'
Builder = require '../../../lib/Package/Builder'

dir = path.resolve(__dirname + '/../../data/package')
pckg = null
builder = null

describe 'Package/Builder.baseNamespace', ->

	beforeEach( ->
		pckg = new Package(path.resolve(dir + '/../..'))
		pckg.base = 'data/package'
		builder = new Builder(pckg)
	)

	describe '#buildModules()', ->
		it 'should build one module from absolute path', (done) ->
			pckg.addModule(dir + '/modules/1.js')
			builder.buildModules().then( (data) ->
				expect(data).to.have.string("'modules/2.js'")
				expect(data).to.have.string("'modules/3.js'")
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

	describe '#build()', ->
		it 'should build whole section', (done) ->
			pckg.addModule('./modules/1.js')
			pckg.addToAutorun('modules/1')
			pckg.addToAutorun('libs/begin/4.js')
			builder.build().then( (data) ->
				expect(data).to.include.keys(['css', 'js'])
				expect(data.js).to.have.string("'modules/2.js'")
				expect(data.js).to.have.string("'modules/3.js'")
				expect(data.js).to.have.string("'module'")
				expect(data.js).to.have.string("require('modules/1.js');")
				expect(data.js).to.have.string('// 4')
				done()
			).done()