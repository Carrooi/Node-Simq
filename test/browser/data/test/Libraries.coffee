

describe 'Libraries & run', ->
	it 'should be created test variable in window', ->
		expect(window._test).to.be.eql(
			initialized: true
			one: true
			two: true
			three: true
		)