expect = require('chai').expect
path = require 'path'
Info = require 'module-info'

Package = require '../../../lib/Package/Package'
Builder = require '../../../lib/Package/Builder'

SyntaxException = require 'source-compiler/Exceptions/SyntaxException'

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

		it 'should return an error for wrong coffee file', (done) ->
			pckg.addModule('./modules/with-error.coffee')
			builder.buildModules().fail( (err) ->
				expect(err).to.be.an.instanceof(Error)
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

	describe '#buildStyles()', ->
		it 'should build styles', (done) ->
			pckg.setStyle('./css/style.less', './public/style.css')
			builder.buildStyles().then( (data) ->
				expect(data).to.be.equal('body {\n  color: #000000;\n}\n')
				done()
			).done()

		it 'should return an error for bad style', (done) ->
			pckg.setStyle('./css/with-errors.less', './public/style.css')
			builder.buildStyles().fail( (err) ->
				expect(err).to.be.an.instanceof(SyntaxException)
				expect(err.message).to.be.equal('missing closing `}`')
				expect(err.line).to.be.equal(1)
				expect(err.column).to.be.equal(0)
				done()
			).done()

	describe '#build()', ->
		it 'should build whole section', (done) ->
			pckg.addModule('./modules/1.js')
			pckg.addToAutorun('modules/1')
			pckg.addToAutorun('libs/begin/4.js')
			builder.build().then( (data) ->
				expect(data).to.include.keys(['css', 'js'])
				expect(data.js).to.have.string("'package/modules/2.js'")
				expect(data.js).to.have.string("'package/modules/3.js'")
				expect(data.js).to.have.string("'module'")
				expect(data.js).to.have.string("require('modules/1.js');")
				expect(data.js).to.have.string('// 4')
				done()
			).done()