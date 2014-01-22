Extension = require 'easy-configuration/lib/Extension'
Helpers = require '../Helpers'
path = require 'path'

class PackageExtension extends Extension


	defaultsPackage:
		skip: false
		target: null
		packagePath: null	# deprecated
		paths:
			package: './package.json'
			npmModules: './node_modules'
		ignore:
			package: null	# deprecated
			main: null		# deprecated
			packageFiles: false
			mainFiles: false
		application: null	# deprecated
		base: null
		style:
			in: null
			out: null
			dependencies: null
		modules: []
		autoNpmModules: true
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

			if pckg.application != null
				throw new Error 'Config: application option is deprecated. Please use target and take a look in the new documentation.'

			if pckg.packagePath != null
				throw new Error 'Config: packagePath option is deprecated. Please use paths.package.'

			if pckg.coreModules != null
				throw new Error 'Config: coreModules section is deprecated. Please take a look in new documentation.'

			if pckg.fsModules != null
				throw new Error 'Config: fsModules section is deprecated. Please take a look in new documentation.'

			if pckg.ignore.package != null
				throw new Error 'Config: ignore.package is deprecated. Please use ignore.packageFiles instead.'

			if pckg.ignore.main != null
				throw new Error 'Config: ignore.main is deprecated. Please use ignore.mainFiles instead.'

			for lib, i in pckg.libraries.begin
				pckg.libraries.begin[i] = '- ' + lib
			for lib, i in pckg.libraries.end
				pckg.libraries.end[i] = '- ' + lib

			pckg.run.unshift.apply(pckg.run, pckg.libraries.begin)
			pckg.run.push.apply(pckg.run, pckg.libraries.end)

			if pckg.style.in == null || pckg.style.out == null
				pckg.style = null

			delete pckg.application
			delete pckg.packagePath
			delete pckg.coreModules
			delete pckg.fsModules
			delete pckg.libraries
			delete pckg.ignore.package
			delete pckg.ignore.main

		return config


module.exports = PackageExtension