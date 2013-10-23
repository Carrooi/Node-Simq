require = window.require

describe 'Info', ->

	beforeEach( ->
		require.release()
	)

	afterEach( ->
		require.release()
	)

	it 'should be true', ->
		expect(require.simq).to.be.true

	it 'should contain version of simq', ->
		expect(require.version).to.be.a('string')