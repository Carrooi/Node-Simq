Extension = require 'easy-configuration/lib/Extension'

class PackageExtension extends Extension


	defaultsPackage:
		application: null
		base: null
		style:
			in: null
			out: null
			dependencies: []
		modules: []
		aliases: {}
		run: []
		libraries:
			begin: []
			end: []


	loadConfiguration: ->
		config = @getConfig()

		for name, pckg of config
			config[name] = @configurator.merge(pckg, @defaultsPackage)

			if pckg.base != null
				pckg.base = pckg.base.replace(/^[\.\/]*/, '').replace(/[\.\/]*$/, '')

		return config


module.exports = PackageExtension