(function () {

	var should = require('should');
	var path = require('path');
	var fs = require('fs');

	var Loader = require('../../lib/Loader');
	var Style = require('../../lib/Parser/Style');
	var Compiler = require('source-compiler');

	var dir = path.resolve(__dirname + '/../data/package');
	var section = {
		cached: {
			style: {
				in: dir + '/css/style.less',
				out: dir + '/css/style.css',
				dependencies: [dir + '/css/common.less']
			}
		},
		loaded: {
			style: {
				in: dir + '/css/style.less',
				out: dir + '/css/style.css',
				dependencies: null
			}
		}
	};
	var result = {
		original: 'body {\n  color: #000000;\n}\n',
		updated: 'body {\n  color: #ffffff;\n}\n'
	};

	var loader = new Loader;
	var style = new Style(loader, section.loaded);

	describe('Style', function() {

		describe('#parse()', function() {

			it('should return parsed less file', function(done) {
				style.parse().then(function(data) {
					data.should.be.equal(result.original);
					done();
				}).done();
			});

			describe('caching', function() {

				beforeEach(function() {
					Compiler.setCache(path.resolve(__dirname + '/../data/cache'));
					style.section = section.cached;
				});

				afterEach(function() {
					Compiler.cache = null;
					style.section = section.loaded;
					fs.writeFileSync(dir + '/css/common.less', '@color: #000000;');
					var file = path.resolve(__dirname + '/../data/cache/__' + Compiler.CACHE_NAMESPACE + '.json');
					if (fs.existsSync(file)) {
						fs.unlinkSync(file);
					}
				});

				it('should load parsed less file from cache', function(done) {
					style.parse().then(function(data) {
						Compiler.cache.load(section.cached.style.in).should.be.equal(result.original);
						done();
					}).done();
				});

				it('should not load less file from cache', function(done) {
					style.section = section.loaded
					style.parse().then(function(data) {
						should.not.exists(Compiler.cache.load(section.cached.style.in));
						done();
					}).done();
				});

				it('should invalidate compiled less file after changes in dependent file', function(done) {
					fs.writeFileSync(dir + '/css/common.less', '@color: #ffffff;');
					style.parse().then(function(data) {
						Compiler.cache.load(section.cached.style.in).should.be.equal(result.updated);
						done();
					}).done();
				});

			});

		})

	});

})();