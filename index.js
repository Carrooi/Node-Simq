(function () {

    var SimQ, s, argv, debug;

    SimQ = require('./lib/SimQ');

	s = new SimQ;

	argv = process.argv;

	if (!argv[2]) {
		throw new Error('Do you want to watch or build application?');	// todo: needs better description
	}

	debug = argv[3] && argv[3] === 'debug' ? true : false;

	if (argv[2] === 'watch') {
		s.watch(!debug);
	} else if (argv[2] === 'build') {
		s.build(!debug);
	} else {
		throw new Error('Unknow action ' + argv[2] + '.');
	}

}).call(this);