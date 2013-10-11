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
		coreModules: null	# deprecated
		fsModules: null		# deprecated
		aliases: {}
		run: []
		libraries:			# deprecated
			begin: []		# deprecated
			end: []			# deprecated


	loadConfiguration: ->
		config = @getConfig()

		for name, pckg of config
			config[name] = @configurator.merge(pckg, @defaultsPackage)

			if pckg.coreModules != null
				throw new Error 'Config: coreModules section is deprecated. Please take a look in new documentation.'

			if pckg.fsModules != null
				throw new Error 'Config: fsModules section is deprecated. Please take a look in new documentation.'

			for lib, i in pckg.libraries.begin
				pckg.libraries.begin[i] = '- ' + lib
			for lib, i in pckg.libraries.end
				pckg.libraries.end[i] = '- ' + lib

			pckg.run.unshift.apply(pckg.run, pckg.libraries.begin)
			pckg.run.push.apply(pckg.run, pckg.libraries.end)

			if pckg.style.in == null || pckg.style.out == null
				pckg.style = null

			delete pckg.coreModules
			delete pckg.fsModules
			delete pckg.libraries

		return config


module.exports = PackageExtension