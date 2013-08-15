Extension = require 'easy-configuration/lib/Extension'
Helpers = require '../Helpers'
path = require 'path'

class PackageExtension extends Extension


	basePath: '.'

	defaultsPackage:
		application: null
		base: null
		style:
			in: null
			out: null
			dependencies: null
		modules: []
		fsModules: {}
		aliases: {}
		run: []
		libraries:
			begin: []
			end: []

	defaultFsModule:
		name: null
		paths: []


	constructor: (@basePath) ->


	loadConfiguration: ->
		config = @getConfig()

		for name, pckg of config
			config[name] = @configurator.merge(pckg, @defaultsPackage)

			if pckg.base != null
				pckg.base = pckg.base.replace(/^[\.\/]*/, '').replace(/[\.\/]*$/, '')

			for _path, data of pckg.fsModules
				if typeof data == 'string'
					data = {
						name: data
					}

				data = @configurator.merge(data, @defaultFsModule)

		return config


	afterCompile: (config) ->
		for name, pckg of config
			basePath = if pckg.base == null then @basePath else @basePath + '/' + pckg.base

			pckg.libraries.begin = Helpers.expandFilesList(pckg.libraries.begin, basePath)
			pckg.libraries.end = Helpers.expandFilesList(pckg.libraries.end, basePath)

			pckg.modules = Helpers.expandFilesList(pckg.modules, basePath)

			for _path, data of pckg.fsModules
				data.paths = Helpers.expandFilesList(data.paths, _path)

			if pckg.application != null
				pckg.application = path.resolve("#{basePath}/#{pckg.application}")

			if pckg.style.in != null && pckg.style.out != null
				pckg.style.in = path.resolve("#{basePath}/#{pckg.style.in}")
				pckg.style.out = path.resolve("#{basePath}/#{pckg.style.out}")

				if pckg.style.dependencies != null
					for dep, i in pckg.style.dependencies
						pckg.style.dependencies[i] = path.resolve("#{basePath}/#{dep}")

		return config


module.exports = PackageExtension