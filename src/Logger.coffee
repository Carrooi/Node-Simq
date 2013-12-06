path = require 'path'
fs = require 'fs'

class Logger


	path: null

	logged: false

	running: true


	constructor: (_path = null) ->
		if _path == null
			@running = false
		else
			@path = if _path == 'console' then _path else path.resolve(_path)


	log: (message) ->
		if @running
			if @logged == false
				@logged = true

				if @path != 'console'
					@log('======================== ' + (new Date).toLocaleString() + ' ========================')

			if @path == 'console'
				console.log(message)
			else
				fs.appendFileSync(@path, message + '\n')

		return message


module.exports = Logger