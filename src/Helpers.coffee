Finder = require 'fs-finder'
Module = require 'module'
fs = require 'fs'
path = require 'path'

class Helpers


	@getGlobalsForModule: (name) ->
		dir = path.dirname(name)

		globals =
			require: "function(name) {return __r__c__.require(name, '#{name}');}"
			'-- require.resolve': "function(name, parent) {if (parent === null) {parent = '#{name}';} return __r__c__.require.resolve(name, parent);}"
			'-- require.define': "function(bundle) {__r__c__.require.define(bundle);}"
			'-- require.cache': "__r__c__.require.cache"
			__filename: "'#{name}'"
			__dirname: "'#{dir}'"
			process: "{cwd: function() {return '/';}, argv: ['node', '#{name}'], env: {}}"

		result = []
		for key, value of globals
			key = if key.match(/^--\s/) == null then "var #{key}" else key.replace(/^--\s/, '')
			result.push("#{key} = #{value};")

		return result


	@getCoreModulesPaths: ->
		return Module.globalPaths


	@getCoreModulePath: (name) ->
		for dir in @getCoreModulesPaths()
			_path = "#{dir}/#{name}.js"
			if fs.existsSync(_path) && fs.statSync(_path).isFile()
				return _path

		return null



module.exports = Helpers