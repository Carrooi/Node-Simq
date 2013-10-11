Q = require 'q'
required = require 'flatten-required'
Info = require 'module-info'
Compiler = require 'source-compiler'
path = require 'path'
fs = require 'fs'

Package = require './Package'
Helpers = require '../Helpers'

class Builder extends Package


	pckg: null

	autoModule: ['.json', '.eco']


	constructor: (@pckg) ->
		if @pckg !instanceof Package
			throw new Error 'Package must be an instance of Package/Package'


	check: ->
		if !fs.existsSync(@pckg.getBasePath() + '/package.json')
			throw new Error 'Package has not got package.json file.'

		@pckg.prepare()


	build: ->
		deferred = Q.defer()

		Q.all([
			@buildModules()
			@buildAutorun()
			@buildStyles()
		]).then( (data) ->
			result = '/** Generated by SimQ **/\n/** modules **/\n\n' + data[0]
			if data[1] != ''
				result += '\n\n/** run section **/\n\n' + data[1]

			deferred.resolve(
				js: result
				css: data[2]
			)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	buildModules: ->
		@check()

		deferred = Q.defer()

		@prepareModules().then( (modules) =>
			c = [@loadMain()]

			for name, _path of modules
				c.push(@compileModule(name, _path))

			for alias, original of @pckg.aliases
				c.push(Q.resolve("'#{alias}': function(exports, module) { module.exports = window.require('#{original}'); }"))

			Q.all(c).then( (data) ->
				main = data.shift()
				deferred.resolve("#{main}({\n#{data}\n});")
			).fail( (err) ->
				deferred.reject(err)
			)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	buildAutorun: ->
		@check()

		deferred = Q.defer()

		run = []
		for _path in @pckg.run
			run.push(@loadForAutorun(_path))

		Q.all(run).then( (data) ->
			deferred.resolve(data.join('\n'))
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	buildStyles: ->
		@check()

		if @pckg.style == null
			return Q.resolve(null)

		deferred = Q.defer()
		options = {}
		if @pckg.style.dependencies != null
			options.dependents = @pckg.style.dependencies

		Compiler.compileFile(@pckg.style.in, options).then( (data) ->
			deferred.resolve(data)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadForAutorun: (_path) ->
		deferred = Q.defer()

		if fs.existsSync(_path)
			Compiler.compileFile(_path).then( (data) ->
				deferred.resolve(data)
			).fail( (err) ->
				deferred.reject(err)
			)
		else
			deferred.resolve("require('#{_path}');")

		return deferred.promise


	prepareModules: ->
		deferred = Q.defer()

		paths = []
		for _path in @pckg.modules
			paths.push(_path)

		required.findMany(paths, true, require('../../data.json').supportedCores).then( (data) =>
			result = {}

			data.files = data.files.concat(paths)
			data.files = data.files.filter( (el, pos) -> return data.files.indexOf(el) == pos)

			for file in data.files
				if @pckg.getPackageInfo().isFileInModule(file)
					result['/' + @pckg.getPackageInfo().getModuleName(file, true)] = file
				else
					info = Info.fromFile(file)
					result[info.getModuleName(file)] = file

			for name, _path in data.core
				if _path != null
					result[name] = _path

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	compileModule: (name, _path) ->
		deferred = Q.defer()

		Compiler.compileFile(_path).then( (result) =>
			type = path.extname(_path)

			if @autoModule.indexOf(type) != -1
				result = "module.exports = #{result}"

			if result != ''
				result = '\n\n\t/** code **/\n\t' + result.replace(/\n/g, '\n\t') + '\n'
			else
				result = '\n'

			globals = '\t' + Helpers.getGlobalsForModule(name).join('\n').replace(/\n/g, '\n\t')
			result = "'#{name}': function(exports, module) {\n\n\t/** node globals **/\n#{globals}#{result}\n}"

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadMain: ->
		deferred = Q.defer()

		_path = path.resolve(__dirname + '/../_Module.js')
		fs.readFile(_path, encoding: 'utf8', (err, data) ->
			if err
				deferred.reject(err)
			else
				data = data.replace(/\s+$/, '').replace(/;$/, '')
				deferred.resolve(data)
		)

		return deferred.promise


module.exports = Builder