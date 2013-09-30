Info = require 'module-info'
fs = require 'fs'
path = require 'path'

Helpers = require './Helpers'

class Package


	basePath: null

	skip: false

	application: null

	base: null

	style: null

	modules: null

	coreModules: null

	fsModules: null

	aliases: null

	run: null

	libraries: null


	constructor: (@basePath) ->
		@basePath = path.resolve(@basePath)

		@modules = {}
		@coreModules = {}
		@fsModules = {}
		@aliases = {}
		@run = []
		@libraries =
			begin: []
			end: []


	setApplication: (@application) ->
		@application = Helpers.resolvePath(@basePath, @application, @base)
		return @


	setStyle: (fileIn, fileOut, dependencies = null) ->
		fileIn = Helpers.resolvePath(@basePath, fileIn, @base)
		fileOut = Helpers.resolvePath(@basePath, fileOut, @base)

		if dependencies != null
				dependencies = Helpers.expandFilesList(dependencies, @basePath, @base)

		@style =
			in: fileIn
			out: fileOut
			dependencies: dependencies

		return @


	addModule: (name) ->
		_path = Helpers.resolvePath(@basePath, './node_modules/' + name, @base)
		if !fs.existsSync(_path)
			throw new Error 'Module ' + name + ' was not found.'

		@modules[name] = new Info(_path)

		return @


	addCoreModule: (name) ->
		if !Helpers.isCoreModuleSupported(name)
			throw new Error 'Core module ' + name + ' is not supported.'

		_path = Helpers.getCoreModulePath(name)

		if _path == null
			throw new Error 'Core module ' + name + ' was not found.'

		@coreModules[name] = _path
		return @


	addFsModule: (_path, paths = null) ->
		if !fs.existsSync(_path)
			throw new Error 'Module ' + _path + ' does not exists.'

		if !fs.statSync(_path).isDirectory()
			throw new Error 'Module ' + _path + ' is not directory.'

		pckg = path.resolve(_path + '/package.json')
		if !fs.existsSync(pckg) || !fs.statSync(pckg).isFile()
			throw new Error 'File ' + pckg + ' was not found.'

		paths = ['./<*.js$>']
		paths = Helpers.expandFilesList(paths, _path)

		@fsModules[_path] = paths
		return @


	addAlias: (original, alias) ->
		@aliases[alias] = original
		return @


	addToAutorun: (name) ->
		@run.push(name)
		return @


	addLibraryToBegin: (_path) ->
		@libraries.begin.push(Helpers.expandFilesList(_path))
		return @


	addLibraryToEnd: (_path) ->
		@libraries.end.push(Helpers.expandFilesList(_path))
		return @


module.exports = Package