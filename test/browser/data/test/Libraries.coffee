

describe 'Libraries & run', ->
	it 'should be created test variable in window', ->
		expect(window._test).to.be.eql(
			initialized: 'hello'
			one: 'hello'
			two: 'hello'
			three: 'hello'
		)