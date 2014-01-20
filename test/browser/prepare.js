var path = require('path');

var SimQ = require('../../lib/SimQ');
var Commands = require('../../lib/Commands');
var Configurator = require('../../lib/Config/Configurator');
var Factory = require('../../lib/Package/Factory');

var basePath = __dirname;
var configPath = basePath + '/config/setup.json';

var simq = new SimQ(basePath);
var commands = new Commands(simq);
var configurator = new Configurator(configPath);

commands.on('build', function(simq) {
	configurator.invalidate();
	var config = configurator.load();

	simq.release();
	simq.jquerify = config.template.jquerify;
	simq.minify = config.debugger.minify;
	simq.stats = config.debugger.filesStats;
	simq.expose = config.debugger.expose;

	for (var name in config.packages) {
		if (config.packages.hasOwnProperty(name)) {
			var pckg = Factory.create(basePath, config.packages[name]);
			simq.addPackage(name, pckg);
		}
	}
});

commands.build().fail(function(err) {
	throw err;
}).done();