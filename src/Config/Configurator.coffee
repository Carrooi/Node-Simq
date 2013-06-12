EasyConfigurator = require 'easy-configuration'
PackageExtension = require './PackageExtension'
TemplateExtension = require './TemplateExtension'

class Configurator extends EasyConfigurator


	constructor: (fileName) ->
		super(fileName)

		@addExtension('packages', new PackageExtension)
		@addExtension('template', new TemplateExtension)


module.exports = Configurator