expect = require('chai').expect
path = require 'path'
Info = require 'module-info'

Package = require '../../../lib/Package/Package'

dir = path.resolve(__dirname + '/../../data/package')
pckg = null

describe '_Package', ->

	beforeEach( ->
		pckg = new Package(dir)
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
			])

	describe '#addModule()', ->
		it 'should add module with absolute path', ->
			pckg.addModule(dir + '/modules/1.js')
			expect(pckg.modules).to.include.keys('package/modules/1.js')
			expect(pckg.modules['package/modules/1.js']).to.be.equal(dir + '/modules/1.js')

		it 'should add modules with absolute path', ->
			pckg.addModule(dir + '/modules/*.js<$>')
			expect(pckg.modules).to.include.keys([
				'package/modules/1.js'
				'package/modules/2.js'
				'package/modules/3.js'
				'package/modules/4.js'
				'package/modules/6.js'
			])

		it 'should add core module', ->
			pckg.addModule('events')
			expect(pckg.modules).to.include.keys('events')

		it 'should add module from base directory', ->
			pckg.addModule('./modules/1.js')
			expect(pckg.modules).to.include.keys('modules/1.js')
			expect(pckg.modules['modules/1.js']).to.be.equal(dir + '/modules/1.js')

		it 'should add modules from base directory', ->
			pckg.addModule('./modules/*.js<$>')
			expect(pckg.modules).to.include.keys([
				'modules/1.js'
				'modules/2.js'
				'modules/3.js'
				'modules/4.js'
				'modules/6.js'
			])

		it 'should add installed npm module', ->
			pckg.addModule('module/test.js')
			expect(pckg.modules).to.include.keys('module/test.js')
			expect(pckg.modules['module/test.js']).to.be.equal(dir + '/node_modules/module/test.js')

		it 'should add installed npm modules', ->
			pckg.addModule('module/*.js<$>')
			expect(pckg.modules).to.include.keys([
				'module',
				'module/test.js',
				'module/test2.js'
			])