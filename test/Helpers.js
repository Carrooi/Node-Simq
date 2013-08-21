(function () {

	var should = require('should');

	var Helpers = require('../lib/Helpers');

	var dir = __dirname + '/data/package';
	var data = {
		modules: {
			relative: [
				'./modules/1.js',
				'./modules/2.js',
				'./modules/3.js',
				'./modules/4.js',
				'./modules/5.json',
				'./modules/6.coffee',
				'./modules/6.js'
			],
			list: [
				dir + '/modules/1.js',
				dir + '/modules/2.js',
				dir + '/modules/3.js',
				dir + '/modules/4.js',
				dir + '/modules/5.json',
				dir + '/modules/6.coffee',
				dir + '/modules/6.js'
			]
		}
	};

	describe('Helpers', function() {

		describe('#expandFilesList()', function() {

			it('should return list of files from directory', function() {
				Helpers.expandFilesList(['./modules'], dir).should.be.eql(data.modules.list);
			});

			it('should return list of files from files', function() {
				Helpers.expandFilesList(data.modules.relative, dir).should.be.eql(data.modules.list);
			});

			it('should return url from list of url', function() {
				var address = 'http://www.my-site.com/script.js';
				Helpers.expandFilesList([address]).should.be.eql([address]);
			});

			it('should return list of files from regex', function() {
				Helpers.expandFilesList(['./modules/<[0-9]\.(js|json|coffee)$>'], dir).should.be.eql(data.modules.list);
			});

		});

		describe('#removeDuplicates()', function() {

			it('should return array without duplicates', function() {
				Helpers.removeDuplicates([1, 1, 1, 2, 2, 3, 1, 1, 2, 4, 6, 3, 4, 2]).should.eql([1, 2, 3, 4, 6]);
			});

		});

	});

})();