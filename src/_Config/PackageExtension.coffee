Extension = require 'easy-configuration/lib/Extension'
Helpers = require '../Helpers'
path = require 'path'

class PackageExtension extends Extension


	defaultsPackage:
		skip: false
		application: null
		base: null
		style:
			in: null
			out: null
			dependencies: null
		modules: []
		coreModules: null
		fsModules: null
		aliases: {}
		run: []
		libraries:
			begin: []
			end: []


	loadConfiguration: ->
		config = @getConfig()

		for name, pckg of config
			if pckg.coreModules != null
				throw new Error 'Config: coreModules section is deprecated. Please take a look in new documentation.'

			if pckg.fsModules != null
				throw new Error 'Config: fsModules section is deprecated. Please take a look in new documentation.'

			delete pckg.coreModules
			delete pckg.fsModules

			config[name] = @configurator.merge(pckg, @defaultsPackage)

		return config


module.exports = PackageExtension