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
		it 'should add new module and create instance of module-info', ->
			pckg.addModule('module')
			expect(pckg.modules.module).to.be.an.instanceof(Info)

		it 'should throw an error if module was not found', ->
			expect( -> pckg.addModule('unknown') ).to.throw(Error)

	describe '#addCoreModule()', ->
		it 'should add events core module', ->
			pckg.addCoreModule('events')
			expect(pckg.coreModules).to.include.keys('events')

		it 'should throw an error if core module is not supported', ->
			expect( -> pckg.addCoreModule('fs') ).to.throw(Error)

	describe '#addFsModule()', ->
		it 'should add new module from disk', ->
			pckg.addFsModule(dir + '/node_modules/module')
			expect(pckg.fsModules).to.include.keys(dir + '/node_modules/module')

		it 'should throw an error if path does not exists', ->
			expect( -> pckg.addFsModule(dir + '/unknown') ).to.throw(Error)

		it 'should throw an error if path is not directory', ->
			expect( -> pckg.addFsModule(dir + '/node_modules/module/index.js') ).to.throw(Error)

		it 'should throw an error if package.json does not exists in directory', ->
			expect( -> pckg.addFsModule(dir + '/libs') ).to.throw(Error)