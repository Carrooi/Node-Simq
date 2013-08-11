path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
Helpers = require '../Helpers'
Package = require '../Package'

class Application


	simq: null

	loader: null

	basePath: null

	section: null

	packageName: null


	constructor: (@simq, @loader, @basePath, @section, @packageName) ->
		@basePath = if @section.base == null then @basePath else @basePath + '/' + @section.base


	parseLibraries: (type) ->
		paths = Helpers.expandFilesList(@section.libraries[type], @basePath)
		return @loader.loadFiles(paths)


	parseModules: ->
		deferred = Q.defer()

		modules = Helpers.expandFilesList(@section.modules, @basePath)
		Package.findDependenciesForModules(modules).then( (data) =>
			@loader.loadModules(data.files, @section.base).then( (modules) =>
				for alias, m of @section.aliases
					modules.push("'#{alias}': '#{m}'")

				@loader.loadFile(__dirname + '/../Module.js').then( (content) =>
					content = content.replace(/\s+$/, '').replace(/;$/, '')

					node = {}
					for m, info of data.node
						main = path.relative(@basePath, info.main)
						name = path.relative(@basePath, m)

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


	parseRun: ->
		run = []
		run.push("this.require('#{m}');") for m in @section.run
		return Q.resolve(run)


	parse: ->
		return Q.all([
			@parseLibraries('begin')
			@parseModules()
			@parseRun()
			@parseLibraries('end')
		]).then( (data) =>
			result = [].concat(data[0], data[1].modules, data[1].node, data[2], data[3])
			result = result.join('\n\n')

			if !@simq.config.load().debugger.scripts
				result = Uglify.minify(result, fromString: true).code

			return Q.resolve(result)
		)


module.exports = Application