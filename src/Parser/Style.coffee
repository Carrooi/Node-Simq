_path = require 'path'
less = require 'less'
fs = require 'fs'
Q = require 'q'

class Style


	basePath: null


	constructor: (@basePath) ->


	parse: (path, minify = true) ->
		load = (path) ->
			path = _path.resolve(path)
			return Q.nfcall(fs.readFile, path, 'utf-8')

		parse = (content) ->
			deferred = Q.defer()
			path = _path.resolve(path)

			options =
				paths: [_path.dirname(path)]
				optimization: 1
				filename: path
				rootpath: ''
				relativeUrls: false
				strictImports: false
				compress: minify

			less.render(content, options, (e, content) -> if e then deferred.reject(e) else deferred.resolve(content) )

			return deferred.promise

		return load(path).then(parse)


module.exports = Style