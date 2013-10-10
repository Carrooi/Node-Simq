Extension = require 'easy-configuration/lib/Extension'

class TemplateExtension extends Extension


	defaults:
		jquerify: false


	loadConfiguration: ->
		return @getConfig(@defaults)


module.exports = TemplateExtension