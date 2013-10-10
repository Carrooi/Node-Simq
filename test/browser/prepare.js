var path = require('path');

var SimQ = require('../../lib/_SimQ');
var Commands = require('../../lib/Commands');
var Configurator = require('../../lib/_Config/Configurator');
var Factory = require('../../lib/Package/Factory');

var basePath = __dirname;
var configPath = basePath + '/config/setup.json';

var simq = new SimQ(basePath);
var commands = new Commands(simq);
var configurator = new Configurator(configPath);

var config = configurator.load()

for (var name in config.packages) {
	if (config.packages.hasOwnProperty(name)) {
		var pckg = Factory.create(basePath, config.packages[name]);
		simq.addPackage(name, pckg);
	}
}

commands.build();