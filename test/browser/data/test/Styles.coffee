
$ = require '/libs/jquery'

describe 'Styles', ->
	it 'should have got red test box', ->
		expect($('#tests').css('backgroundColor')).to.be.equal('rgb(255, 0, 0)')