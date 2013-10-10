expect = require('chai').expect
path = require 'path'

Factory = require '../../../lib/Package/Factory'
Package = require '../../../lib/Package/Package'
Configurator = require '../../../lib/_Config/Configurator'

dir = path.resolve(__dirname + '/../../data/package')
configDir = dir + '/config'

getConfig = (name) -> return (new Configurator(configDir + '/' + name + '.json')).load()

describe 'Package/Factory', ->

	describe '#create()', ->
		it 'shoult create empty package', ->
			config = getConfig('empty')
			pckg = Factory.create(dir, config.packages.application)
			expect(pckg).to.be.an.instanceof(Package)
			expect(pckg.basePath).to.be.equal(dir)
			expect(pckg.skip).to.be.false
			expect(pckg.base).to.be.null
			expect(pckg.application).to.be.null
			expect(pckg.style).to.be.null
			expect(pckg.modules).to.be.eql([])
			expect(pckg.run).to.be.eql([])