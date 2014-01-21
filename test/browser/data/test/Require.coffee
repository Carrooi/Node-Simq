

# rewrite module specific require
require = window.require

$ = require '/libs/jquery'


describe 'require', ->

	beforeEach( ->
		require.release()
	)

	afterEach( ->
		require.release()
	)

	describe '#resolve()', ->
		it 'should return same name for module', ->
			expect(require.resolve('/app/Application.coffee')).to.be.equal('/app/Application.coffee')

		it 'should return name of module without extension', ->
			expect(require.resolve('/app/Application')).to.be.equal('/app/Application.coffee')

		it 'should return name of module from parent', ->
			expect(require.resolve('./Application.coffee', '/app/Bootstrap.coffee')).to.be.equal('/app/Application.coffee')

		it 'should return name of module from parent without extension', ->
			expect(require.resolve('./Application', '/app/Bootstrap.coffee')).to.be.equal('/app/Application.coffee')

		it 'should resolve name in root directory', ->
			expect(require.resolve('/setup.js')).to.be.equal('/setup.js')

		it 'should resolve name in root without extension', ->
			expect(require.resolve('/setup')).to.be.equal('/setup.js')

		it 'should resolve name for main file', ->
			expect(require.resolve('/index.js')).to.be.equal('/index.js')

		it 'should resolve name for main file without extension', ->
			expect(require.resolve('/index')).to.be.equal('/index.js')

		it 'should resolve name for package file', ->
			expect(require.resolve('/package.json')).to.be.equal('/package.json')

		it 'should resolve name for package file withoud extension', ->
			expect(require.resolve('/package')).to.be.equal('/package.json')

		it 'should normalize absolute path', ->
			expect(require.resolve('/app/../app/../app/Application')).to.be.equal('/app/Application.coffee')

		it 'should throw an error if module with given path does not exists', ->
			expect( -> require.resolve('./any-random-name')).to.throw(Error, 'Module ./any-random-name was not found.')

	describe '#require()', ->
		it 'should load simple module', ->
			expect(require('/app/Application.coffee')).to.be.equal('Application')

		it 'should load simple module without extension', ->
			expect(require('/app/Application')).to.be.equal('Application')

		it 'should load package file', ->
			data = require '/package'
			expect(data).to.include.keys(['name'])
			expect(data.name).to.be.equal('browser-test')

		it 'should load package from alias', ->
			expect(require('app')).to.be.equal('Application')

		it 'should load npm module', ->
			expect(require('any')).to.be.equal('hello')

		it 'should load npm module main file directly', ->
			expect(require('any/index')).to.be.equal('hello')

		it 'should load package file from npm module', ->
			data = require('any/package')
			expect(data).to.include.keys(['name'])
			expect(data.name).to.be.equal('any')

		it.skip 'should load node core module', ->
			events = new require('events').EventEmitter
			expect(events).to.satisfy( (events) -> return Object.prototype.toString.call(events) == '[object Function]')

		it 'should load eco template', ->
			template = require('/app/views/message')(name: 'David')
			expect(template).to.be.an.instanceof($)
			expect(template.html()).to.be.equal('hello David')

		it 'should load advanced npm module', ->
			expect(require('advanced')).to.be.equal('advanced/one/two/three')

		it 'should load advanced npm module with relative requires', ->
			expect(require('advanced/other.js')).to.be.equal('advanced/one/two/three')

		it 'should load npm module with another main file', ->
			expect(require('another')).to.be.equal('SimQ')

		it.skip 'should test module which uses core module', (done) ->
			obj = new (require('/app/WithEvents'))
			obj.on 'call', (message) ->
				expect(message).to.be.equal('hello')
				done()
			obj.callMe()

		it 'should load module with require to relative module in it', ->
			expect(require('/app/Bootstrap')).to.be.equal('Bootstrap - Application')

		it 'should load circular modules', ->
			require.define('circular/first', (exports, m) ->
				expect(require('circular/second')).to.be.equal('second')
				m.exports = 'first'
			)
			require.define('circular/second', (exports, m) ->
				expect(require('circular/first')).to.be.eql({})
				m.exports = 'second'
			)

			expect(require 'circular/first').to.be.equal('first')

		it 'data from configurable module should be already in window', ->
			expect(window.__configurable__module__).to.be.true

		it 'should load module with alias from configurable module', ->
			expect(require('shortcut')).to.be.equal('shortcut')

	describe 'cache', ->
		it 'should be empty', ->
			expect(require.cache).to.be.eql({})

		it 'should contain required module', ->
			require('/app/Application')
			expect(require.cache).to.include.keys(['/app/Application.coffee'])

		it 'should load random number from cache', ->
			old = require('/app/Random').generate()
			expect(old).to.be.equal(require('/app/Random').generate())

		it 'should save module to cache again', ->
			old = require('/app/Random').generate()
			name = require.resolve('/app/Random')
			delete require.cache[name]
			expect(old).not.to.be.equal(require('/app/Random').generate())