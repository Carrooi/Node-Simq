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


	parseLibraries: (type) ->
		base = if @section.base == null then @basePath else @basePath + '/' + @section.base
		return Helpers.loadLibraries(@loader, @section.libs[type], base)


	parseModules: ->
		deferred = Q.defer()
		base = if @section.base == null then @basePath else @basePath + '/' + @section.base
		Helpers.findDependentModulesFromList(@section.modules, base).then( (data) =>
			Helpers.loadModules(@loader, data.files, @section.base).then( (modules) =>
				for alias, module of @section.aliases
					modules.push('\'' + alias + '\': \'' + module + '\'')

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
						modules: content + '({' + modules.join(',\n') + '\n});'
						node: 'require._setNodeInfo(' + JSON.stringify(node) + ');\n'

					deferred.resolve(result)
				, (e) ->
					deferred.reject(e)
				)
			)
		)
		return deferred.promise


	parseRun: ->
		run = []
		for module in @section.run
			run.push('this.require(\'' + module + '\');')

		return Q.resolve(run)


	parse: ->
		return Q.all([
			@parseLibraries('begin')
			@parseModules()
			@parseLibraries('end')
			@parseRun()
		]).then( (data) =>
			result = [].concat(data[0], data[1].modules, data[1].node, data[2], data[3])
			result = result.join('\n\n')

			if !@simq.config.load().debugger.scripts then result = Uglify.minify(result, fromString: true).code

			return Q.resolve(result)
		)


module.exports = Application