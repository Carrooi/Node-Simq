(function () {

	var should = require('should');
	var Compiler = require('source-compiler');
	var fs = require('fs');

	var Loader = require('../lib/Loader');

	var dir = __dirname + '/data';
	var loader = new Loader;

	var files = {
		json: {
			file: dir + '/package/modules/5.json',
			name: 'data/package/modules/5.json',
			result: "'data/package/modules/5.json': function(exports, __require, module) {\n" + Loader.getGlobalsForModule('data/package/modules/5.json').join('\n') + "\n(function() {\nreturn {\n\t\"message\": \"linux\"\n}\n}).call(this);\n\n}"
		},
		less: {
			file: dir + '/package/css/style.less',
			result: 'body {\n  color: #ff0000;\n}\n'
		}
	}

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