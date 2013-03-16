(function () {

    var SimQ, s, argv;

    SimQ = require('./lib/SimQ');

	s = new SimQ;

	argv = process.argv;

	if (!argv[2]) {
		throw new Error('Do you want to watch or build application?');
	}

	if (argv[2] === 'watch') {
		s.watch();
	} else if (argv[2] === 'build') {
		s.build();
	} else {
		throw new Error('Unknow action ' + argv[2] + '.');
	}

}).call(this);