path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
Helpers = require './ApplicationHelpers'

class Application


	simq: null

	loader: null

	basePath: null

	section: null

	packageName: null


	constructor: (@simq, @loader, @basePath, @section, @packageName) ->


	parseLibraries: (base, list) ->
		return Helpers.loadLibraries(@loader, list, base)


	parseModules: (sectionBase, base, modules, aliases) ->
		deferred = Q.defer()

		Helpers.findDependentModulesFromList(modules, base).then( (data) =>
			Helpers.loadModules(@loader, data.files, sectionBase).then( (modules) =>
				for alias, module of aliases
					modules.push("'#{alias}': '#{module}'")

				@loader.loadFile(__dirname + '/../Module.js').then( (content) =>
					content = content.replace(/\s+$/, '').replace(/;$/, '')
					base = path.resolve(base)

					node = {}
					for module, info of data.node
						main = path.relative(base, info.main)
						name = path.relative(base, module)

						main = main.replace(/^[./]+/, '')
						name = name.replace(/^[./]+/, '')

						node[name] =
							name: info.name
							path: main

					result =
						modules: content + '({\n' + modules.join(',\n') + '\n});'
						node: 'require._setNodeInfo(' + JSON.stringify(node) + ');\n'

					deferred.resolve(result)
				, (e) ->
					deferred.reject(e)
				)
			)
		)
		return deferred.promise


	parseRun: (list) ->
		run = []
		run.push("this.require('#{module}');") for module in list
		return Q.resolve(run)


	parse: ->
		base = if @section.base == null then @basePath else @basePath + '/' + @section.base

		nodeModules = Helpers.translateNodeModulesList(@section.nodeModules)
		modules = @section.modules.concat(nodeModules)

		return Q.all([
			@parseLibraries(base, @section.libraries.begin)
			@parseModules(@section.base, base, modules, @section.aliases)
			@parseRun(@section.run)
			@parseLibraries(base, @section.libraries.end)
		]).then( (data) =>
			result = [].concat(data[0], data[1].modules, data[1].node, data[2], data[3])
			result = result.join('\n\n')

			if !@simq.config.load().debugger.scripts then result = Uglify.minify(result, fromString: true).code

			return Q.resolve(result)
		)


module.exports = Application