Package = require './Package'

class Factory


	@create: (basePath, config) ->
		pckg = new Package(basePath)
		pckg.skip = config.skip
		pckg.base = config.base

		if config.application != null
			pckg.setApplication(config.application)

		if config.style != null
			pckg.setStyle(config.style.in, config.style.out, config.style.dependencies)

		for m in config.modules
			pckg.addModule(m)

		for name, m of config.aliases
			pckg.addAlias(m, name)

		for name in config.run
			pckg.addToAutorun(name)

		return pckg


module.exports = Factory