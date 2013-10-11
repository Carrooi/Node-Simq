

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

		it.skip 'should resolve name for main file', ->
			expect(require.resolve('/index.js')).to.be.equal('/index.js')

	describe '#require()', ->
		it 'should load simple module', ->
			expect(require('/app/Application.coffee')).to.be.equal('Application')

		it 'should load simple module without extension', ->
			expect(require('/app/Application')).to.be.equal('Application')

	describe 'cache', ->
		it 'should be empty', ->
			expect(require.cache).to.be.eql({})

		it 'should contain required module', ->
			require('/app/Application')
			expect(require.cache).to.include.keys(['/app/Application.coffee'])