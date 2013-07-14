EasyConfigurator = require 'easy-configuration'
PackageExtension = require './PackageExtension'
TemplateExtension = require './TemplateExtension'
CacheExtension = require './CacheExtension'
DebuggerExtension = require './DebuggerExtension'

class Configurator extends EasyConfigurator


	constructor: (fileName, debug = false) ->
		super(fileName)

		@addExtension('packages', new PackageExtension)
		@addExtension('template', new TemplateExtension)
		@addExtension('cache', new CacheExtension)
		@addExtension('debugger', new DebuggerExtension(debug))


module.exports = Configurator