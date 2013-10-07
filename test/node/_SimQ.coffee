expect = require('chai').expect
path = require 'path'

SimQ = require '../../lib/_SimQ'
Package = require '../../lib/Package/Package'

dir = path.resolve(__dirname + '/../data/package')
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