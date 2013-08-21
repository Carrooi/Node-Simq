(function () {

	var should = require('should');
	var required = require('required');

	var Package = require('../lib/Package');
	var Helpers = require('../lib/Helpers');


	var dir = __dirname + '/data';
	var simpleModulePath = dir + '/package/node_modules/module/index.js';
	var advancedModulePath = dir + '/package/node_modules/module/node_modules/another_one/file.json';
	var invalidModule = dir + '/some_file.js';

	var pckg = new Package(dir);

	console.log(pckg.findSystemNodeModulePath('events'));

	var modules = {
		list: [
			'./modules/<[0-9]>.js',
			'./modules/4.js',
			'./modules/6.coffee',
			'./modules/*.<(json|coffee)$>'
		],
		expected: [
			dir + '/package/modules/1.js',
			dir + '/package/modules/2.js',
			dir + '/package/modules/3.js',
			dir + '/package/modules/4.js',
			dir + '/package/modules/5.json',
			dir + '/package/modules/6.coffee'
		]
	};

	describe('Package', function() {

		describe('#isInModule()', function() {

			it('should return true when file is in node modules', function() {
				pckg.isInModule(simpleModulePath).should.be.true;
				pckg.isInModule(advancedModulePath).should.be.true;
			});

			it('should return false when file is not in node modules', function() {
				pckg.isInModule(invalidModule).should.be.false;
			});

		});

		describe('#getModuleName()', function() {

			it('should return module name when file is in node module', function() {
				pckg.getModuleName(simpleModulePath).should.equal('module');
				pckg.getModuleName(advancedModulePath).should.equal('another_one');
			});

			it('should return null when file is not in node module', function() {
				should.not.exist(pckg.getModuleName(invalidModule));
			});

		});

		describe('#getModuleBaseDir()', function() {

			it('should return module directory for file if file is node module', function() {
				pckg.getModuleBaseDir(simpleModulePath).should.equal(dir + '/package/node_modules/module');
				pckg.getModuleBaseDir(advancedModulePath).should.equal(dir + '/package/node_modules/module/node_modules/another_one');
			});

			it('should return null if file is not in node module', function() {
				should.not.exist(pckg.getModuleBaseDir(invalidModule));
			});

		});

		describe('#resolveModuleName()', function() {

			it('should return expanded file path', function() {
				pckg.resolveModuleName(dir + '/package/node_modules/module/index').should.equal(dir + '/package/node_modules/module/index.js');
				pckg.resolveModuleName(dir + '/package/node_modules/module/node_modules/another_one/something').should.equal(dir + '/package/node_modules/module/node_modules/another_one/something/index.json');
			});

			it('should return null when expanded file was not found', function() {
				should.not.exist(pckg.resolveModuleName(dir + '/random_file'));
			});

		});

		describe('#findModulePackageFile()', function() {

			it('should return path to package.json file if file is in node module', function() {
				pckg.findModulePackageFile(simpleModulePath).should.equal(dir + '/package/node_modules/module/package.json');
				pckg.findModulePackageFile(advancedModulePath).should.equal(dir + '/package/node_modules/module/node_modules/another_one/package.json');
			});

			it('should return null if file is not in node module', function() {
				should.not.exist(pckg.findModulePackageFile(invalidModule));
			});

		});

		describe('#loadModuleInfo()', function() {

			it('should return information from parsed package.json if file is in node module', function() {
				pckg.loadModuleInfo(simpleModulePath).should.eql({
					file: dir + '/package/node_modules/module/index.js',
					name: 'module',
					main: dir + '/package/node_modules/module/index.js',
					dir: dir + '/package/node_modules/module'
				});
				pckg.loadModuleInfo(advancedModulePath).should.eql({
					file: dir + '/package/node_modules/module/node_modules/another_one/file.json',
					name: 'another_one',
					main: dir + '/package/node_modules/module/node_modules/another_one/something/index.json',
					dir: dir + '/package/node_modules/module/node_modules/another_one'
				});
			});

			it('should return null if file is not in node module', function() {
				should.not.exist(pckg.loadModuleInfo(invalidModule));
			})
		});

		describe('#findDependencies()', function() {
			it('should return object with dependencies from given file', function(done) {
				pckg.findDependencies(dir + '/package/modules/1.js').then(function(data) {
					var expect = {
						files: [
							dir + '/package/modules/1.js',
							dir + '/package/modules/2.js',
							dir + '/package/modules/3.js',
							dir + '/package/node_modules/module/index.js'
						],
						core: ['fs', 'path'],
						node: {}
					};
					expect.node[dir + '/package/node_modules/module'] = {
						name: 'module',
						main: dir + '/package/node_modules/module/index.js'
					};

					data.should.eql(expect);
					done();
				}).done();
			});
		});

		describe('#findDependenciesForModules()', function() {

			it('should return object with information for modules from modules list in configuration', function(done) {
				var list = Helpers.expandFilesList(modules.list, dir + '/package');
				pckg.findDependenciesForModules(list).then(function(data) {
					var expect = {
						files: [
							'/var/www/node/simq/test/data/package/modules/1.js',
							'/var/www/node/simq/test/data/package/modules/2.js',
							'/var/www/node/simq/test/data/package/modules/3.js',
							'/var/www/node/simq/test/data/package/node_modules/module/index.js',
							'/var/www/node/simq/test/data/package/modules/4.js',
							'/var/www/node/simq/test/data/package/modules/5.json',
							'/var/www/node/simq/test/data/package/modules/6.js',
							'/var/www/node/simq/test/data/package/modules/6.coffee'
						],
						core: ['fs', 'path'],
						node: {}
					};
					expect.node[dir + '/package/node_modules/module'] = {
						name: 'module',
						main: '/var/www/node/simq/test/data/package/node_modules/module/index.js'
					};

					data.should.eql(expect);
					done();
				}).done();
			});

		});

		describe('#parseDependencies()', function() {

			it('should return list of dependencies from required module', function(done) {
				var dep = required(dir + '/package/modules/1.js', {ignoreMissing: true}, function(e, deps) {
					pckg.parseDependencies(deps[0]).should.eql({
						files: [
							dir + '/package/modules/2.js',
							dir + '/package/modules/3.js',
							dir + '/package/node_modules/module/index.js'
						],
						core: ['fs', 'path']
					});
					done();
				});
			});

		});

		describe('#getGlobalsForModule()', function() {

			it('should return array with js code of node global variables for browser', function() {
				pckg.getGlobalsForModule('test/module/name.js').should.eql([
					"var require = function(name) {return __require(name, 'test/module/name.js');};",
					"var __filename = 'test/module/name.js';",
					"var __dirname = 'test/module';"
				]);
			});

		});

	});

})();