expect = require('chai').expect
path = require 'path'
Info = require 'module-info'

Package = require '../../../lib/Package/Package'

dir = path.resolve(__dirname + '/../../data/package')
pckg = null

describe 'Package/Package.baseNamespace', ->

	beforeEach( ->
		pckg = new Package(path.resolve(dir + '/../../'))
		pckg.base = 'data/package'
	)

	describe '#setApplication()', ->
		it 'should set path for result js file', ->
			pckg.setApplication('./public/application.js')
			expect(pckg.application).to.be.equal(dir + '/public/application.js')

	describe '#setStyle()', ->
		it 'should set paths for styles without dependent files', ->
			pckg.setStyle('./css/style.less', './public/style.css')
			expect(pckg.style.in).to.be.equal(dir + '/css/style.less')
			expect(pckg.style.out).to.be.equal(dir + '/public/style.css')
			expect(pckg.style.dependencies).to.be.null

		it 'should set paths for styles with dependent files', ->
			pckg.setStyle('./css/style.less', './public/style.css', ['./css/*.less'])
			expect(pckg.style.dependencies).to.be.eql([
				dir + '/css/common.less'
				dir + '/css/style.less'
				dir + '/css/variables.less'
				dir + '/css/with-errors.less'
			])

		it 'should throw an error if input file does not exists', ->
			expect( -> pckg.setStyle('./css/unknown.less', './public/style.css')).to.throw(Error)

	describe '#addModule()', ->
		it 'should add module with absolute path', ->
			pckg.addModule(dir + '/modules/1.js')
			expect(pckg.modules).to.be.eql([dir + '/modules/1.js'])

		it 'should add modules with absolute path', ->
			pckg.addModule(dir + '/modules/*.js<$>')
			expect(pckg.modules).to.be.eql([
				dir + '/modules/1.js'
				dir + '/modules/2.js'
				dir + '/modules/3.js'
				dir + '/modules/4.js'
				dir + '/modules/6.js'
				dir + '/modules/other/index.js'
			])

		it.skip 'should add core module', ->
			pckg.addModule('events')
			expect(pckg.modules).to.have.length.above(0)
			expect(pckg.modules[0]).not.to.be.null

		it 'should add module from base directory', ->
			pckg.addModule('./modules/1.js')
			expect(pckg.modules).to.be.eql([dir + '/modules/1.js'])

		it 'should add modules from base directory', ->
			pckg.addModule('./modules/*.js<$>')
			expect(pckg.modules).to.be.eql([
				dir + '/modules/1.js'
				dir + '/modules/2.js'
				dir + '/modules/3.js'
				dir + '/modules/4.js'
				dir + '/modules/6.js'
				dir + '/modules/other/index.js'
			])

		it 'should add installed npm module', ->
			pckg.addModule('module/test.js')
			expect(pckg.modules).to.be.eql([dir + '/node_modules/module/test.js'])

		it 'should add installed npm modules', ->
			pckg.addModule('module/*.js<$>')
			expect(pckg.modules).to.be.eql([
				dir + '/node_modules/module/index.js',
				dir + '/node_modules/module/test.js',
				dir + '/node_modules/module/test2.js'
			])

	describe '#addAlias()', ->
		it 'should create new module for alias', ->
			pckg.addModule('module/test.js')
			pckg.addAlias('/module/test.js', 'test')
			expect(pckg.aliases).to.be.eql(
				test: '/module/test.js'
			)
			expect(pckg.modules).to.be.eql([
				dir + '/node_modules/module/test.js'
			])

		it 'should create new module for alias without extension', ->
			pckg.addModule('module/test.js')
			pckg.addAlias('/module/test', 'test')
			expect(pckg.aliases).to.be.eql(
				test: '/module/test'
			)
			expect(pckg.modules).to.be.eql([
				dir + '/node_modules/module/test.js'
			])

		it 'should create new module for alias without exact file path', ->
			pckg.addModule('module/any/index.json')
			pckg.addAlias('/module/any', 'any')
			expect(pckg.aliases).to.be.eql(
				any: '/module/any'
			)
			expect(pckg.modules).to.be.eql([
				dir + '/node_modules/module/any/index.json'
			])

	describe '#addToAutorun()', ->
		it 'should add module to autorun', ->
			pckg.addModule('module/test.js')
			pckg.addToAutorun('/module/test.js')
			expect(pckg.run).to.be.eql(['/module/test.js'])

		it 'should add module to autorun without extension', ->
			pckg.addModule('module/test.js')
			pckg.addToAutorun('/module/test')
			expect(pckg.run).to.be.eql(['/module/test'])

		it 'should add module to autorun without exact file path', ->
			pckg.addModule('module/any/index.json')
			pckg.addToAutorun('/module/any')
			expect(pckg.run).to.be.eql(['/module/any'])

		it 'should add library from absolute path', ->
			pckg.addToAutorun('- ' + dir + '/libs/begin/1.js')
			expect(pckg.run).to.be.eql([dir + '/libs/begin/1.js'])

		it 'should add library from relative path', ->
			pckg.addToAutorun('- ./libs/begin/1.js')
			expect(pckg.run).to.be.eql([dir + '/libs/begin/1.js'])

		it 'should add all js libraries from absolute path', ->
			pckg.addToAutorun('- ' + dir + '/libs/begin/*.js<$>')
			expect(pckg.run).to.be.eql([
				dir + '/libs/begin/1.js'
				dir + '/libs/begin/2.js'
				dir + '/libs/begin/3.js'
				dir + '/libs/begin/4.js'
				dir + '/libs/begin/6.js'
			])

		it 'should add all js libraries from relative path', ->
			pckg.addToAutorun('- ./libs/begin/*.js<$>')
			expect(pckg.run).to.be.eql([
				dir + '/libs/begin/1.js'
				dir + '/libs/begin/2.js'
				dir + '/libs/begin/3.js'
				dir + '/libs/begin/4.js'
				dir + '/libs/begin/6.js'
			])