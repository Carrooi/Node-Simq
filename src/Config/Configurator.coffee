EasyConfigurator = require 'easy-configuration'
PackageExtension = require './PackageExtension'
TemplateExtension = require './TemplateExtension'
DebuggerExtension = require './DebuggerExtension'

class Configurator extends EasyConfigurator


	constructor: (fileName, debug = false) ->
		super(fileName)

		@addExtension('packages', new PackageExtension)
		@addExtension('template', new TemplateExtension)
		@addExtension('debugger', new DebuggerExtension(debug))


module.exports = Configurator