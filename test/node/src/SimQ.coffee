expect = require('chai').expect
path = require 'path'
fs = require 'fs'

SimQ = require '../../../lib/SimQ'
Package = require '../../../lib/Package/Package'

dir = path.resolve(__dirname + '/../../data/package')
simq = null

describe 'SimQ', ->

	beforeEach( ->
		simq = new SimQ(dir)
	)

	describe '#addPackage()', ->
		it 'should add new instance of Package class', ->
			simq.addPackage('test')
			expect(simq.packages).to.include.keys('test')
			expect(simq.packages.test).to.be.an.instanceof(Package)

		it 'should throw an error if package is already added', ->
			simq.addPackage('test')
			expect( -> simq.addPackage('test') ).to.throw(Error)

		it 'should add new package directly', ->
			pckg = new Package(dir)
			simq.addPackage('test', pckg)
			expect(simq.hasPackage('test')).to.be.true
			expect(simq.getPackage('test')).to.be.equal(pckg)

		it 'should throw an error if package to add is not an instance of Package/Package', ->
			expect( -> simq.addPackage('test', new Array)).to.throw(Error, 'Package test must be an instance of Package/Package.')

	describe '#hasPackage()', ->
		it 'should return false', ->
			expect(simq.hasPackage('test')).to.be.false

		it 'should return true', ->
			simq.addPackage('test')
			expect(simq.hasPackage('test')).to.be.true

	describe '#getPackage()', ->
		it 'should return instance of created package', ->
			simq.addPackage('test')
			expect(simq.getPackage('test')).to.be.an.instanceof(Package)

		it 'should throw an error if package is not registered', ->
			expect( -> simq._getPackage('test') ).to.throw(Error)

	describe '#removePackage()', ->
		it 'should remove registered package', ->
			simq.addPackage('test')
			simq.removePackage('test')
			expect(simq.packages).not.to.include.keys('test')

		it 'should throw an error if package is not registered', ->
			expect( -> simq.removePackage('test') ).to.throw(Error)

	describe '#build()', ->
		it 'should build all sections', (done) ->
			pckg = simq.addPackage('test')
			pckg.addModule('./modules/1.js')
			pckg.addToAutorun('/modules/1')
			pckg.addToAutorun('- ./libs/begin/4.js')
			simq.build().then( (data) ->
				expect(data).to.include.keys(['test'])
				expect(data.test).to.include.keys(['css', 'js'])
				expect(data.test.js).to.have.string("'/modules/2.js'")
				expect(data.test.js).to.have.string("'/modules/3.js'")
				expect(data.test.js).to.have.string("'module'")
				expect(data.test.js).to.have.string("require('/modules/1');")
				expect(data.test.js).to.have.string('// 4')
				done()
			).done()

	describe '#buildToFiles()', ->
		afterEach( ->
			if fs.existsSync(dir + '/public/application.js')
				fs.unlinkSync(dir + '/public/application.js')
		)

		it 'should build sections to files', (done) ->
			pckg = simq.addPackage('test')
			pckg.addModule('./modules/1.js')
			pckg.addToAutorun('/modules/1')
			pckg.addToAutorun('- ./libs/begin/4.js')
			pckg.setTarget('public/application.js')
			simq.buildToFiles().then( (data) ->
				data = fs.readFileSync(dir + '/public/application.js', encoding: 'utf8')

				expect(data).to.have.string("'/modules/2.js'")
				expect(data).to.have.string("'/modules/3.js'")
				expect(data).to.have.string("'module'")
				expect(data).to.have.string("require('/modules/1');")
				expect(data).to.have.string('// 4')
				done()
			).done()