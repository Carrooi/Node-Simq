path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
merge = require 'recursive-merge'
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

				result =
					modules: modules.join(',\n')
					node: Package.parseNodeInfo(data.node, @basePath)

				deferred.resolve(result)
			, (err) ->
				deferred.reject(err)
			)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadFsModules: ->
		deferred = Q.defer()

		modules = []
		for _path, data of @section.fsModules
			modules.push @loadFsModule(data.name, _path, data.paths)

		Q.all(modules).then( (data) ->
			deferred.resolve(data)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadFsModule: (name, _path, paths) ->
		deferred = Q.defer()

		Package.findDependenciesForModules(paths).then( (deps) =>
			modules = {}
			for file in deps.files
				_name = name + '/' + path.relative(_path, file)
				modules[_name] = file

			@loader.loadModules(modules, _path).then( (result) ->
				result =
					modules: result.join(',\n')
					node: Package.parseNodeInfo(deps.node, _path)

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
			@loadBaseModuleFile(),
			@loadFsModules()
		]).then( (data) =>
			modules = [data[0].modules]
			modules.push sub.modules for sub in data[2]
			modules = modules.join(',\n')

			node = merge(data[0].node, sub.node) for sub in data[2]
			node = JSON.stringify(node)

			result =
				modules: "#{data[1]}({\n#{modules}\n});"
				node: "require._setNodeInfo(#{node});\n"

			deferred.resolve(result)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	parseRun: ->
		run = []

		for m in @section.run
			if (match = m.match(/^<(.+)>$/)) == null
				run.push("this.require('#{m}');")
			else
				run.push(match[1])

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