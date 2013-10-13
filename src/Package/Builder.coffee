Q = require 'q'
required = require 'flatten-required'
Info = require 'module-info'
Compiler = require 'source-compiler'
Module = require 'module'
path = require 'path'
fs = require 'fs'
escapeRegexp = require 'escape-regexp'
uglifyJs = require 'uglify-js'
cleanCss = require 'clean-css'

Package = require './Package'
Helpers = require '../Helpers'

class Builder extends Package


	pckg: null

	jquerify: false

	minify: false

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

			if @minify == true
				result = uglifyJs.minify(result, fromString: true).code
				data[2] = cleanCss.process(data[2])

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
				c.push(Q.resolve(" '#{alias}': function(exports, module) { module.exports = window.require('#{original}'); }\n"))

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
			deferred.resolve(data.join('\n\n'))
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
			Compiler.compileFile(_path).then( (data) =>
				p = path.relative(@pckg.getBasePath(), _path)
				data = "/** #{p} **/\n#{data}"
				deferred.resolve(data)
			).fail( (err) ->
				deferred.reject(err)
			)
		else
			deferred.resolve("/** #{_path} **/\nrequire('#{_path}');")

		return deferred.promise


	prepareModules: ->
		deferred = Q.defer()

		required.findMany(@pckg.modules, true, require('../../data.json').supportedCores).then( (data) =>
			result = {}

			data.files = data.files.concat(@pckg.modules)
			data.files = data.files.filter( (el, pos) -> return data.files.indexOf(el) == pos)

			for file in data.files
				# module in package
				if @pckg.getPackageInfo().isFileInModule(file)
					result['/' + @pckg.getPackageInfo().getModuleName(file, true)] = file

				# core or npm module
				else
					dir = path.dirname(file)

					# installed npm module
					if Module.globalPaths.indexOf(dir) == -1
						info = Info.fromFile(file)
						name = info.getModuleName(file)
						result[name] = file

						baseName = escapeRegexp(path.basename(file))
						if name.match(new RegExp(baseName + '$')) == null
							fullName = info.getName() + '/' + path.relative(info.getPath(), file)
							@pckg.addAlias(name, fullName)

					# core module
					else
						name = path.basename(file, path.extname(file))
						result[name] = file

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

		Compiler.compileFile(_path, {precompile: true, jquerify: @jquerify}).then( (result) =>
			type = path.extname(_path)

			if @autoModule.indexOf(type) != -1
				result = "module.exports = #{result}"

			if result != ''
				result = '\n\n\t/** code **/\n\t' + result.replace(/\n/g, '\n\t') + '\n'
			else
				result = '\n'

			globals = '\t' + Helpers.getGlobalsForModule(name).join('\n').replace(/\n/g, '\n\t')
			result = " '#{name}': function(exports, module) {\n\n\t/** node globals **/\n#{globals}#{result}\n}"

			deferred.resolve(result)
		).fail( (err) ->
			deferred.reject(err)
		)

		return deferred.promise


	loadMain: ->
		deferred = Q.defer()

		_path = path.resolve(__dirname + '/../Module.js')
		fs.readFile(_path, encoding: 'utf8', (err, data) ->
			if err
				deferred.reject(err)
			else
				data = data.replace(/\s+$/, '').replace(/;$/, '')
				deferred.resolve(data)
		)

		return deferred.promise


module.exports = Builder