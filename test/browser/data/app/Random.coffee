class Random


	num: null


	generate: ->
		if @num == null
			@num = Math.random()

		return @num


module.exports = new Random