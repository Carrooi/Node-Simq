require = window.require

describe 'getStats', ->

	beforeEach( ->
		require.release()
	)

	afterEach( ->
		require.release()
	)

	it 'should get file stats for module', ->
		date = require.getStats('/test/Stats').atime
		expect(date).not.to.be.null
		expect(date).to.be.an.instanceof(Date)

	describe '#__setStats()', ->
		it 'should not exists', ->
			expect(require.__setStats).to.be.undefined