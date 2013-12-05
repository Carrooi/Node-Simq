expect = require('chai').expect
path = require 'path'

Configurator = require '../../../lib/Config/Configurator'

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
				target: null
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

		it 'should load configuration with includes', ->
			config = getConfig('advanced/config')
			expect(config.packages.application.target).to.be.equal('./public/application.js')

		it 'should load configuration with styles', ->
			styles = getConfig('styles/styles').packages.application.style
			expect(styles.in).to.be.equal('./css/style.less')
			expect(styles.out).to.be.equal('./public/style.css')

		it 'should not load styles from configuration because there is no in file', ->
			styles = getConfig('styles/no-in').packages.application.style
			expect(styles).to.be.null

		it 'should not load styles from configuration because there is no out file', ->
			styles = getConfig('styles/no-out').packages.application.style
			expect(styles).to.be.null

		it 'should load transformed libraries section into run section', ->
			config = getConfig('libraries')
			expect(config.packages.application.run).to.be.eql([
				'- ./libs/begin/1.js'
				'- ./libs/begin/2.js'
				'- ./libs/end/1.js'
				'- ./libs/end/2.js'
			])

		it 'should load config with modules in run section', ->
			config = getConfig('run')
			expect(config.packages.application.run).to.be.eql([
				'/app/Application'
				'/app/controllers/Menu.js'
			])

		it 'should load config with modules in run section and with libraries', ->
			config = getConfig('run-and-libraries')
			expect(config.packages.application.run).to.be.eql([
				'- ./libs/begin/1.js'
				'- ./libs/begin/2.js'
				'/app/Application'
				'/app/controllers/Menu.js'
				'- ./libs/end/1.js'
				'- ./libs/end/2.js'
			])