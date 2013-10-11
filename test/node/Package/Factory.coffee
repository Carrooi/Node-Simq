expect = require('chai').expect
path = require 'path'

Factory = require '../../../lib/Package/Factory'
Package = require '../../../lib/Package/Package'
Configurator = require '../../../lib/_Config/Configurator'

dir = path.resolve(__dirname + '/../../data/package')
configDir = dir + '/config'

getConfig = (name) -> return (new Configurator(configDir + '/' + name + '.json')).load()
createPackage = (name) -> return Factory.create(dir, getConfig(name).packages.application)

describe 'Package/Factory', ->

	describe '#create()', ->
		it 'shoult create empty package', ->
			pckg = createPackage('empty')
			expect(pckg).to.be.an.instanceof(Package)
			expect(pckg.basePath).to.be.equal(dir)
			expect(pckg.skip).to.be.false
			expect(pckg.base).to.be.null
			expect(pckg.application).to.be.null
			expect(pckg.style).to.be.null
			expect(pckg.modules).to.be.eql([])
			expect(pckg.run).to.be.eql([])

		it 'should create package with result application path', ->
			pckg = createPackage('advanced/config')
			expect(pckg.application).to.be.equal(dir + '/public/application.js')

		it 'should create package with styles', ->
			pckg = createPackage('styles/styles')
			expect(pckg.style).to.be.eql(
				in: dir + '/css/style.less'
				out: dir + '/public/style.css'
				dependencies: null
			)

		it 'should create package without styles because there is no in file', ->
			pckg = createPackage('styles/no-in')
			expect(pckg.style).to.be.null

		it 'should create package without styles because there is no out file', ->
			pckg = createPackage('styles/no-out')
			expect(pckg.style).to.be.null

		it 'should create package with run section from libraries', ->
			pckg = createPackage('libraries')
			expect(pckg.run).to.be.eql([
				dir + '/libs/begin/1.js'
				dir + '/libs/begin/2.js'
				dir + '/libs/end/1.js'
				dir + '/libs/end/2.js'
			])

		it 'should create package with modules to run', ->
			pckg = createPackage('run')
			expect(pckg.modules).to.be.eql([
				dir + '/app/Application.coffee'
				dir + '/app/controllers/Menu.js'
			])
			expect(pckg.run).to.be.eql([
				'/app/Application'
				'/app/controllers/Menu.js'
			])

		it 'should create package with modules and libraries in run section', ->
			pckg = createPackage('run-and-libraries')
			expect(pckg.modules).to.be.eql([
				dir + '/app/Application.coffee'
				dir + '/app/controllers/Menu.js'
			])
			expect(pckg.run).to.be.eql([
				dir + '/libs/begin/1.js'
				dir + '/libs/begin/2.js'
				'/app/Application'
				'/app/controllers/Menu.js'
				dir + '/libs/end/1.js'
				dir + '/libs/end/2.js'
			])