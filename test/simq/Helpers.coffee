expect = require('chai').expect
path = require 'path'

Helpers = require '../../lib/Helpers'

dir = path.normalize(__dirname + '/../data/package')

data =
	modules:
		relative: [
			'./modules/1.js'
			'./modules/2.js'
			'./modules/3.js'
			'./modules/4.js'
			'./modules/5.json'
			'./modules/6.coffee'
			'./modules/6.js'
		]
		list: [
			dir + '/modules/1.js',
			dir + '/modules/2.js',
			dir + '/modules/3.js',
			dir + '/modules/4.js',
			dir + '/modules/5.json',
			dir + '/modules/6.coffee',
			dir + '/modules/6.js'
		]

describe 'Helpers', ->

	describe '#expandFilesList()', ->
		it 'should return list of files from directory', ->
			expect(Helpers.expandFilesList(['./modules'], dir)).to.be.eql(data.modules.list)

		it 'should return list of files from files', ->
			expect(Helpers.expandFilesList(data.modules.relative, dir)).to.be.eql(data.modules.list)

		it 'should return url from list of url', ->
			address = 'http://www.my-site.com/script.js'
			expect(Helpers.expandFilesList([address])).to.be.eql([address])

		it 'should return list of files from regex', ->
			expect(Helpers.expandFilesList(['./modules/<[0-9]\.(js|json|coffee)$>'], dir)).to.be.eql(data.modules.list)

	describe '#removeDuplicates()', ->
		it 'should return array without duplicates', ->
			expect(Helpers.removeDuplicates([1, 1, 1, 2, 2, 3, 1, 1, 2, 4, 6, 3, 4, 2])).to.be.eql([1, 2, 3, 4, 6])