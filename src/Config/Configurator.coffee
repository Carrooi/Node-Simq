EasyConfigurator = require 'easy-configuration'
PackageExtension = require './PackageExtension'
TemplateExtension = require './TemplateExtension'
CacheExtension = require './CacheExtension'
DebuggerExtension = require './DebuggerExtension'
ServerExtension = require './ServerExtension'
RoutesExtension = require './RoutesExtension'

class Configurator extends EasyConfigurator


	constructor: (fileName, pckg, basePath) ->
		super(fileName)

		@addExtension('packages', new PackageExtension(pckg, basePath))
		@addExtension('template', new TemplateExtension)
		@addExtension('cache', new CacheExtension)
		@addExtension('debugger', new DebuggerExtension)
		@addExtension('server', new ServerExtension)
		@addExtension('routes', new RoutesExtension)


module.exports = Configurator