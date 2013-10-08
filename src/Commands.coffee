fs = require 'fs'
ncp = require 'ncp'
path = require 'path'
express = require 'express'

class Commands


	simq: null

	v: false


	constructor: (@simq) ->


	server: ->


	build: ->
		@simq.buildToFiles()


	watch: ->
		@build()

		ignore = new Array
		for name, pckg of @simq.packages
			if pckg.application != null then ignore.push(pckg.application)
			if pckg.style != null then ignore.push(pckg.style.out)

		watch.watchTree(@basePath, {},  (file, curr, prev) =>
			if typeof file == 'string' && file.match(/~$/) == null && file.match(/^\./) == null && ignore.indexOf(path.resolve(file)) == -1		# filter in option is not working...
				console.log file if @v
				@build()
		)


	create: (name) ->
		if !name
			throw new Error 'Please enter name of new application.'

		_path = path.resolve(name)

		if fs.existsSync(_path)
			throw new Error 'Directory with ' + name + ' name is already exists.'

		ncp.ncp(path.normalize(__dirname + '/../sandbox'), _path, (err) ->
			if err
				throw new Error 'There is some error with creating new application.'
		)


	clean: ->
		for name, pckg in @simq.packages
			if pckg.application != null && fs.existsSync(pckg.application)
				console.log "Removing '#{pckg.application}' file" if @v
				fs.unlinkSync(pckg.application)

			if pckg.style != null && fs.existsSync(pckg.style.out)
				console.log "Removing '#{pckg.style.out}' file" if @v
				fs.unlinkSync(pckg.style.out)

			#if config.cache.directory != null
			#	_path = path.resolve(@basePath + '/' + config.cache.directory + '/__source_compiler.json')
			#	if fs.existsSync(_path)
			#		console.log "Removing temp files" if @v
			#		fs.unlinkSync(_path)



module.exports = Commands