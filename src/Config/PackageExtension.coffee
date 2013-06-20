Extension = require 'easy-configuration/lib/Extension'

class PackageExtension extends Extension


	defaultsPackage:
		application: null
		base: null
		style:
			in: null
			out: null
		modules: []
		aliases: {}
		run: []
		libs:
			begin: []
			end: []


	loadConfiguration: ->
		config = @getConfig()

		for name, pckg of config
			config[name] = @configurator.merge(pckg, @defaultsPackage)

		return config


module.exports = PackageExtension