(function () {

	var should = require('should');

	var Loader = require('../../lib/Loader/Loader');

	describe('Loader', function() {

		describe('#getGlobalsForModule()', function() {
			it('should return array with js code of node global variables for browser', function() {
				Loader.getGlobalsForModule('test/module/name.js').should.eql([
					"var require = function(name) {return __require(name, 'test/module/name.js');};",
					"var __filename = 'test/module/name.js';",
					"var __dirname = 'test/module';"
				]);
			});
		});

	});

})();