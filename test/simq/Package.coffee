expect = require('chai').expect
required = require 'required'
path = require 'path'

Package = require '../../lib/Package'
Helpers = require '../../lib/Helpers'

dir = path.normalize(__dirname + '/../data')
simpleModulePath = dir + '/package/node_modules/module/index.js'
advancedModulePath = dir + '/package/node_modules/module/node_modules/another_one/file.json'
invalidModule = dir + '/some_file.js'

pckg = new Package(dir)

modules =
	list: [
		'./modules/<[0-9]>.js'
		'./modules/4.js'
		'./modules/6.coffee'
		'./modules/*.<(json|coffee)$>'
	]
	expected: [
		dir + '/package/modules/1.js'
		dir + '/package/modules/2.js'
		dir + '/package/modules/3.js'
		dir + '/package/modules/4.js'
		dir + '/package/modules/5.json'
		dir + '/package/modules/6.coffee'
	]

describe 'Package', ->

	describe '#isInModule()', ->
		it 'should return true when file is in node modules', ->
			expect(pckg.isInModule(simpleModulePath)).to.be.true
			expect(pckg.isInModule(advancedModulePath)).to.be.true

		it 'should return false when file is not in node modules', ->
			expect(pckg.isInModule(invalidModule)).to.be.false

	describe '#getModuleName()', ->
		it 'should return module name when file is in node module', ->
			expect(pckg.getModuleName(simpleModulePath)).to.be.equal('module')
			expect(pckg.getModuleName(advancedModulePath)).to.be.equal('another_one')

		it 'should return null when file is not in node module', ->
			expect(pckg.getModuleName(invalidModule)).to.be.null

	describe '#getModuleBaseDir()', ->
		it 'should return module directory for file if file is node module', ->
			expect(pckg.getModuleBaseDir(simpleModulePath)).to.be.equal(dir + '/package/node_modules/module')
			expect(pckg.getModuleBaseDir(advancedModulePath)).to.be.equal(dir + '/package/node_modules/module/node_modules/another_one')

		it 'should return null if file is not in node module', ->
			expect(pckg.getModuleBaseDir(invalidModule)).to.be.null

	describe '#resolveModuleName()', ->
		it 'should return expanded file path', ->
			expect(pckg.resolveModuleName(dir + '/package/node_modules/module/index')).to.be.equal(dir + '/package/node_modules/module/index.js')
			expect(pckg.resolveModuleName(dir + '/package/node_modules/module/node_modules/another_one/something')).to.be.equal(dir + '/package/node_modules/module/node_modules/another_one/something/index.json')

		it 'should return null when expanded file was not found', ->
			expect(pckg.resolveModuleName(dir + '/random_file')).to.be.null

	describe '#findModulePackageFile()', ->
		it 'should return path to package.json file if file is in node module', ->
			expect(pckg.findModulePackageFile(simpleModulePath)).to.be.equal(dir + '/package/node_modules/module/package.json')
			expect(pckg.findModulePackageFile(advancedModulePath)).to.be.equal(dir + '/package/node_modules/module/node_modules/another_one/package.json')

	describe '#loadModuleInfo()', ->
		it 'should return information from parsed package.json if file is in node module', ->
			expect(pckg.loadModuleInfo(simpleModulePath)).to.be.eql(
				file: dir + '/package/node_modules/module/index.js'
				name: 'module'
				main: dir + '/package/node_modules/module/index.js'
				dir: dir + '/package/node_modules/module'
			)
			expect(pckg.loadModuleInfo(advancedModulePath)).to.be.eql(
				file: dir + '/package/node_modules/module/node_modules/another_one/file.json'
				name: 'another_one'
				main: dir + '/package/node_modules/module/node_modules/another_one/something/index.json'
				dir: dir + '/package/node_modules/module/node_modules/another_one'
			)

		it 'should return null if file is not in node module', ->
			expect(pckg.loadModuleInfo(invalidModule)).to.be.null

	describe '#findDependencies()', ->
		it 'should return object with dependencies from given file', (done) ->
			pckg.findDependencies(dir + '/package/modules/1.js').then( (data) ->
				should =
					files: [
						dir + '/package/modules/1.js'
						dir + '/package/modules/2.js'
						dir + '/package/modules/3.js'
						dir + '/package/node_modules/module/index.js'
					]
					core: ['fs', 'path']
					node: {}
				should.node[dir + '/package/node_modules/module'] =
					name: 'module'
					main: dir + '/package/node_modules/module/index.js'

				expect(data).to.be.eql(should)
				done()
			).done()

	describe '#findDependenciesForModules()', ->
		it 'should return object with information for modules from modules list in configuration', (done) ->
			list = Helpers.expandFilesList(modules.list, dir + '/package')
			pckg.findDependenciesForModules(list).then( (data) ->
				should =
					files: [
						'/var/www/node/simq/test/data/package/modules/1.js'
						'/var/www/node/simq/test/data/package/modules/2.js'
						'/var/www/node/simq/test/data/package/modules/3.js'
						'/var/www/node/simq/test/data/package/node_modules/module/index.js'
						'/var/www/node/simq/test/data/package/modules/4.js'
						'/var/www/node/simq/test/data/package/modules/5.json'
						'/var/www/node/simq/test/data/package/modules/6.js'
						'/var/www/node/simq/test/data/package/modules/6.coffee'
					]
					core: ['fs', 'path']
					node: {}
				should.node[dir + '/package/node_modules/module'] =
					name: 'module'
					main: '/var/www/node/simq/test/data/package/node_modules/module/index.js'

				expect(data).to.be.eql(should)
				done()
			).done()

	describe '#parseDependencies()', ->
		it 'should return list of dependencies from required module', (done) ->
			required(dir + '/package/modules/1.js', ignoreMissing: true, (e, deps) ->
				expect(pckg.parseDependencies(deps[0])).to.be.eql(
					files: [
						dir + '/package/modules/2.js'
						dir + '/package/modules/3.js'
						dir + '/package/node_modules/module/index.js'
					]
					core: ['fs', 'path']
				)
				done()
			)