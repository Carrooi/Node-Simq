expect = require('chai').expect
Compiler = require 'source-compiler'
fs = require 'fs'
path = require 'path'

Loader = require '../../lib/Loader'
Package = require '../../lib/Package'
Helpers = require '../../lib/Helpers'

dir = path.normalize(__dirname + '/../data')
loader = new Loader(new Package)

files =
	json:
		file: dir + '/package/modules/5.json'
		name: 'data/package/modules/5.json'
		result: "'data/package/modules/5.json': function(exports, __require, module) {\n" + Helpers.getGlobalsForModule('data/package/modules/5.json').join('\n') + "\nmodule.exports = (function() {\nreturn {\n\t\"message\": \"linux\"\n}\n}).call(this);\n\n}"
	less:
		file: dir + '/package/css/style.less'
		result: 'body {\n  color: #000000;\n}\n'

describe 'Loader', ->

	describe '#loadModule()', ->
		it 'should return error if file type can not be loaded as module', (done) ->
			loader.loadModule(dir + '/package/css/style.less').fail( (err) ->
				expect(err).to.be.an.instanceof(Error)
				done()
			).done()

		it 'should return error if file is in remote server', (done) ->
			loader.loadModule('http://www.my-site.com/file.js').fail( (err) ->
				expect(err).to.be.an.instanceof(Error)
				done()
			).done()

		it 'should load json module', (done) ->
			loader.loadModule(files.json.file).then( (data) ->
				expect(data).to.be.equal(files.json.result)
				done()
			).done()

	describe '#loadModules()', ->
		it 'should return parsed list of loaded modules', (done) ->
			loader.loadModules([dir + '/package/modules/1.js']).then( (data) ->
				globals = Helpers.getGlobalsForModule('data/package/modules/1.js').join('\n')
				content = "'data/package/modules/1.js': function(exports, __require, module) {\n" + globals + "\nrequire('./2');\n}"

				expect(data).to.be.eql([content])
				done()
			).done()

	describe 'caching', ->

		beforeEach( ->
			Compiler.setCache(dir + '/cache')
		)

		afterEach( ->
			Compiler.cache = null
			if fs.existsSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json')
				fs.unlinkSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json')
		)

		it 'should load json module from cache', (done) ->
			loader.loadModule(files.json.file).then( (data) ->
				expect(Compiler.cache.load(files.json.file)).to.be.equal('(function() {\nreturn {\n\t"message": "linux"\n}\n}).call(this);\n')
				done()
			).done()

		it 'should not save less file to cache', (done) ->
			loader.loadFile(files.less.file).then( (data) ->
				expect(Compiler.cache.load(files.less.file)).to.be.null
				done()
			).done()

		it 'should save less file to cache', (done) ->
			loader.loadFile(files.less.file, []).then( (data) ->
				expect(Compiler.cache.load(files.less.file)).to.be.equal(files.less.result)
				done()
			).done()