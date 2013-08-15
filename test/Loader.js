(function () {

	var should = require('should');
	var Compiler = require('source-compiler');
	var fs = require('fs');

	var Loader = require('../lib/Loader');
	var Package = require('../lib/Package');

	var dir = __dirname + '/data';
	var loader = new Loader;

	var files = {
		json: {
			file: dir + '/package/modules/5.json',
			name: 'data/package/modules/5.json',
			result: "'data/package/modules/5.json': function(exports, __require, module) {\n" + Package.getGlobalsForModule('data/package/modules/5.json').join('\n') + "\nmodule.exports = (function() {\nreturn {\n\t\"message\": \"linux\"\n}\n}).call(this);\n\n}"
		},
		less: {
			file: dir + '/package/css/style.less',
			result: 'body {\n  color: #000000;\n}\n'
		}
	}

	describe('Loader', function() {

		describe('#loadModule()', function() {

			it('should return error if file type can not be loaded as module', function(done) {
				loader.loadModule(dir + '/package/css/style.less').fail(function(err) {
					err.should.be.an.instanceOf(Error);
					done();
				}).done();
			});

			it('should return error if file is in remote server', function(done) {
				loader.loadModule('http://www.my-site.com/file.js').fail(function(err) {
					err.should.be.an.instanceOf(Error);
					done();
				}).done();
			});

			it('should load json module', function(done) {
				loader.loadModule(files.json.file).then(function(data) {
					data.should.be.equal(files.json.result);
					done();
				}).done();
			});

		});

		describe('#loadModules()', function() {
			it('should return parsed list of loaded modules', function(done) {
				loader.loadModules([dir + '/package/modules/1.js']).then(function(data) {
					var globals = Package.getGlobalsForModule('data/package/modules/1.js').join('\n');
					var content = "'data/package/modules/1.js': function(exports, __require, module) {\n" + globals + "\nrequire('./2');\n}";

					data.should.eql([content]);
					done();
				}).done();
			});
		});

		describe('caching', function() {

			beforeEach(function() {
				Compiler.setCache(dir + '/cache');
			});

			afterEach(function() {
				Compiler.cache = null;
				if (fs.existsSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json')) {
					fs.unlinkSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json');
				}
			});

			it('should load json module from cache', function(done) {
				loader.loadModule(files.json.file).then(function(data) {
					Compiler.cache.load(files.json.file).should.be.equal('(function() {\nreturn {\n\t"message": "linux"\n}\n}).call(this);\n');
					done();
				}).done();
			});

			it('should not save less file to cache', function(done) {
				loader.loadFile(files.less.file).then(function(data) {
					should.not.exists(Compiler.cache.load(files.less.file));
					done();
				}).done();
			});

			it('should save less file to cache', function(done) {
				loader.loadFile(files.less.file, []).then(function(data) {
					Compiler.cache.load(files.less.file).should.be.equal(files.less.result);
					done();
				}).done();
			});

		});

	});

})();