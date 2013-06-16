_path = require 'path'
less = require 'less'
fs = require 'fs'

class Style


	simq: null

	loader: null

	basePath: null


	constructor: (@simq, @loader, @basePath) ->


	parse: (path, minify = true, fn) ->
		path = _path.resolve(path)
		file = fs.readFileSync(path).toString()

		options =
			paths: [_path.dirname(path)]
			optimization: 1
			filename: path
			rootpath: ''
			relativeUrls: false
			strictImports: false
			compress: minify

		less.render(file, options, (e, content) ->
			fn(content)
		)

		return @


module.exports = Style