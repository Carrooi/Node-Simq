expect = require('chai').expect
path = require 'path'

Factory = require '../../../lib/Package/Factory'
Configurator = require '../../../lib/_Config/Configurator'

dir = path.resolve(__dirname + '/../../data/package/config')

getConfig = (name) -> return (new Configurator(dir + '/' + name + '.json')).load()

describe 'Package/Factory', ->

	describe '#create()', ->
		it 'shoult create empty package', ->
			config = getConfig('empty')
			pckg = Factory.create(config.packages.application)
