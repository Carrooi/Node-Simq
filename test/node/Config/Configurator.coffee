expect = require('chai').expect
path = require 'path'

Configurator = require '../../../lib/_Config/Configurator'

dir = path.resolve(__dirname + '/../../data/package/config')

getConfig = (name) -> return (new Configurator(dir + '/' + name + '.json')).load()

describe 'Configurator', ->

	describe '#load()', ->
		it 'should load empty configuration', ->
			config = getConfig('empty')
			expect(config).to.include.keys(['packages', 'template', 'cache', 'debugger', 'server', 'routes'])
			expect(config.packages).to.include.keys(['application'])
			expect(config.packages.application).to.be.eql(
				skip: false
				application: null
				base: null
				style: null
				modules: []
				aliases: {}
				run: []
			)

		it 'should throw an error when there is fsModules section', ->
			expect( -> getConfig('fs-modules')).to.throw(Error, 'Config: fsModules section is deprecated. Please take a look in new documentation.')

		it 'should throw an error when there is coreModules section', ->
			expect( -> getConfig('core-modules')).to.throw(Error, 'Config: coreModules section is deprecated. Please take a look in new documentation.')

