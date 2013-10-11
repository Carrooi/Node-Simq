

require = window.require


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

	describe '#require()', ->
		it 'should load simple module', ->
			expect(require('/app/Application.coffee')).to.be.equal('Application')

		it 'should load simple module without extension', ->
			expect(require('/app/Application')).to.be.equal('Application')

		it 'should load package file', ->
			expect(require('/package')).to.be.eql(
				name: 'browser-test'
				version: '1.0.0'
			)

		it 'should load package from alias', ->
			expect(require('app')).to.be.equal('Application')

	describe 'cache', ->
		it 'should be empty', ->
			expect(require.cache).to.be.eql({})

		it 'should contain required module', ->
			require('/app/Application')
			expect(require.cache).to.include.keys(['/app/Application.coffee'])