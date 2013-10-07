expect = require('chai').expect
path = require 'path'
fs = require 'fs'

Loader = require '../../../lib/Loader'
Style = require '../../../lib/Parser/Style'
Compiler = require 'source-compiler'

dir = path.normalize(__dirname + '/../../data/package')

section =
	cached:
		style:
			in: dir + '/css/style.less'
			out: dir + '/css/style.css'
			dependencies: [dir + '/css/common.less']
	loaded:
		style:
			in: dir + '/css/style.less'
			out: dir + '/css/style.css'
			dependencies: null

result =
	original: 'body {\n  color: #000000;\n}\n'
	updated: 'body {\n  color: #ffffff;\n}\n'

loader = new Loader
style = new Style(loader, section.loaded)

describe 'Style', ->

	describe '#parse()', ->
		it 'should return parsed less file', (done) ->
			style.parse().then( (data) ->
				expect(data).to.be.equal(result.original)
				done()
			).done()

		describe 'caching', ->

			beforeEach( ->
				Compiler.setCache(path.resolve(__dirname + '/../../data/cache'))
				style.section = section.cached
			)

			afterEach( ->
				Compiler.cache = null
				style.section = section.loaded
				fs.writeFileSync(dir + '/css/common.less', '@color: #000000;')
				file = path.resolve(__dirname + '/../../data/cache/__' + Compiler.CACHE_NAMESPACE + '.json')
				if fs.existsSync(file)
					fs.unlinkSync(file)
			)

			it 'should load parsed less file from cache', (done) ->
				style.parse().then( (data) ->
					expect(Compiler.cache.load(section.cached.style.in)).to.be.equal(result.original)
					done()
				).done()

			it 'should not load less file from cache', (done) ->
				style.section = section.loaded
				style.parse().then( (data) ->
					expect(Compiler.cache.load(section.cached.style.in)).to.be.null
					done()
				).done()

			it 'should invalidate compiled less file after changes in dependent file', (done) ->
				fs.writeFileSync(dir + '/css/common.less', '@color: #ffffff;')
				style.parse().then( (data) ->
					expect(Compiler.cache.load(section.cached.style.in)).to.be.equal(result.updated)
					done()
				).done()