fs = require 'fs'
_path = require 'path'

class Config


	path: ''

	data: null

	includable: ['modules', 'aliases', 'run', 'libs']

	defaults:
		packages: {}

	defaultsPackage:
		include: null
		application: null
		style:
			in: null
			out: null
		modules: []
		aliases: {}
		run: []
		libs:
			begin: {}
			end: {}



	constructor: (@path) ->


	load: ->
		if @data == null
			@data = @loadConfig(@path)

		return @data


	loadConfig: (path, included = false) ->
		path = _path.resolve(path)

		if not fs.existsSync(path)
			throw new Error 'Config file ' + path + ' was not found.'

		data = JSON.parse(fs.readFileSync(path))

		if included
			data = @parseSection(data, true)
		else
			if !data.packages
				config =
					packages:
						__main__: data
				data = config

			for name, pckg of data.packages
				data.packages[name] = @parseSection(pckg)

		return data


	parseSection: (section, included = false) ->
		if section.main
			section.application = section.main
			delete section.main

		if !included && section.include
			data = @loadConfig(section.include, true)

			for key, value of data
				if @includable.indexOf(key) == -1
					throw new Error 'Cannot include ' + key + ' section'

				if section[key]
					section[key] = @merge(key, section[key], value)
				else
					section[key] = value

		return section


	merge: (key, data, defaults) ->
		_type = Object.prototype.toString
		type = _type.call(data)

		if type != _type.call(defaults)
			throw new Error 'Cannot include ' + key + ' section. Source and target sections are not the same type.'

		if type == '[object Array]'
			data = defaults.concat(data)

		else if type == '[object Object]'
			for key, value of defaults
				type = _type.call(value)

				if type == '[object String]' && !data[key]
					data[key] = value
				else if type == '[object Array]'
					data[key] = if data[key] then value.concat(data[key]) else value

		return data


module.exports = Config