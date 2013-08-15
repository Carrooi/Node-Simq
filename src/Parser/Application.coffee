path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
Helpers = require '../Helpers'
Package = require '../Package'

class Application


	minify: false

	loader: null

	basePath: null

	section: null


	constructor: (@loader, @basePath, @section) ->


	parseLibraries: (type) ->
		return @loader.loadFiles(@section.libraries[type])


	parseAliases: ->
		result = []
		for alias, m of @section.aliases
			result.push("'#{alias}': '#{m}'")

		return result


	loadBaseModuleFile: ->
		deferred = Q.defer()

		@loader.loadFile(path.resolve(__dirname + '/../Module.js')).then( (content) ->
			content = content.replace(/\s+$/, '').replace(/;$/, '')
			deferred.resolve(content)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadModules: ->
		deferred = Q.defer()

		Package.findDependenciesForModules(@section.modules).then( (data) =>
			@loader.loadModules(data.files, @section.base).then( (modules) =>
				modules = modules.concat(@parseAliases())

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
					modules: modules.join(',\n')
					node: JSON.stringify(node)

				deferred.resolve(result)
			, (err) ->
				deferred.reject(err)
			)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	parseModules: ->
		deferred = Q.defer()

		Q.all([
			@loadModules(),
			@loadBaseModuleFile()
		]).then( (data) =>
			result =
				modules: "#{data[1]}({\n#{data[0].modules}\n});"
				node: "require._setNodeInfo(#{data[0].node});\n"

			deferred.resolve(result)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	parseRun: ->
		run = []
		run.push("this.require('#{m}');") for m in @section.run
		return Q.resolve(run)


	parse: ->
		deferred = Q.defer()

		Q.all([
			@parseLibraries('begin')
			@parseModules()
			@parseRun()
			@parseLibraries('end')
		]).then( (data) =>
			result = [].concat(data[0], data[1].modules, data[1].node, data[2], data[3])
			result = result.join('\n\n')

			if @minify == true
				result = Uglify.minify(result, fromString: true).code

			deferred.resolve(result)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


module.exports = Application