path = require 'path'
Uglify = require 'uglify-js'
Q = require 'q'
merge = require 'recursive-merge'
Helpers = require '../Helpers'

class Application


	minify: false

	loader: null

	pckg: null

	basePath: null

	section: null

	v: false


	constructor: (@loader, @pckg, @basePath, @section) ->


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

		@pckg.findDependenciesForModules(@section.modules).then( (data) =>
			@loader.loadModules(data.files, @section.base).then( (modules) =>
				modules = modules.concat(@parseAliases())

				result =
					modules: modules.join(',\n')
					node: @pckg.parseNodeInfo(data.node, @basePath)

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
		for _path, paths of @section.fsModules
			modules.push @loadFsModule(_path, paths)

		Q.all(modules).then( (data) ->
			deferred.resolve(data)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadFsModule: (_path, paths) ->
		deferred = Q.defer()
		info = @pckg.loadModuleInfo("#{_path}/package.json")

		@pckg.findDependenciesForModules(paths).then( (deps) =>
			modules = {}
			for file in deps.files
				_name = info.name + '/' + path.relative(_path, file)
				modules[_name] = file

			@loader.loadModules(modules, _path).then( (result) =>
				result =
					modules: result.join(',\n')
					node: @pckg.parseNodeInfo(deps.node, path.dirname(_path))

				deferred.resolve(result)
			, (err) ->
				deferred.reject(err)
			)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadCoreModules: ->
		deferred = Q.defer()

		promises = []
		msg = []
		for name, _path of @section.coreModules
			msg.push "Loading core module '#{name}' from '#{_path}'"
			promises.push @loader.loadModule(_path, null, name)

		if promises.length == 0
			return Q.resolve('')

		if @v
			paths = Helpers.getCoreModulesPaths()
			if paths.length == 0
				console.log 'Core modules will not be loaded. No system module path found.'
			else
				console.log 'Core modules will be searched in these paths:\n' + paths.join('\n')

			for m in msg
				console.log m

		Q.all(promises).then( (data) ->
			data = data.join(',\n')
			deferred.resolve(data)
		)

		return deferred.promise


	parseModules: ->
		deferred = Q.defer()

		Q.all([
			@loadModules(),
			@loadBaseModuleFile(),
			@loadFsModules(),
			@loadCoreModules()
		]).then( (data) =>
			final =
				modules: data[0].modules
				node: data[0].node

			for pack in data[2]
				final.modules += ',\n' if final.modules != '' && pack.modules != ''
				final.modules += pack.modules if pack.modules != ''
				final.node = merge(final.node, pack.node)

			if data[3] != ''
				final.modules += ',\n' if final.modules != ''
				final.modules += data[3]

			final.node = JSON.stringify(final.node)

			result =
				modules: "#{data[1]}({\n#{final.modules}\n});"
				node: "require._setMeta(#{final.node});\n"

			deferred.resolve(result)
		, (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	parseRun: ->
		run = []

		for m in @section.run
			if (match = m.match(/^<(.+)>$/)) == null
				run.push("require('#{m}');")
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