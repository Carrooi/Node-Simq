expect = require('chai').expect
path = require 'path'

SimQ = require '../../lib/SimQ'
Package = require '../../lib/Package/Package'

dir = path.resolve(__dirname + '/../data/package')
simq = null


describe 'SimQ', ->

	beforeEach( ->
		simq = new SimQ(null, dir)
	)

	describe '#addPackage()', ->
		it 'should add new instance of Package class', ->
			simq.addPackage('test')
			expect(simq.packages).to.include.keys('test')
			expect(simq.packages.test).to.be.an.instanceof(Package)

		it 'should throw an error if package is already added', ->
			simq.addPackage('test')
			expect( -> simq.addPackage('test') ).to.throw(Error)

	describe '#_getPackage()', ->
		it 'should return instance of created package', ->
			simq.addPackage('test')
			expect(simq._getPackage('test')).to.be.an.instanceof(Package)

		it 'should throw an error if package is not registered', ->
			expect( -> simq._getPackage('test') ).to.throw(Error)

	describe '#removePackage()', ->
		it 'should remove registered package', ->
			simq.addPackage('test')
			simq.removePackage('test')
			expect(simq.packages).not.to.include.keys('test')

		it 'should throw an error if package is not registered', ->
			expect( -> simq.removePackage('test') ).to.throw(Error)