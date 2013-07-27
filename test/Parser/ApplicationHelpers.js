(function() {

	var should = require('should');
	var path = require('path');
	var required = require('required');

	var ApplicationHelpers = require('../../lib/Parser/ApplicationHelpers');
	var SimQ = require('../../lib/SimQ');
	var Loader = require('../../lib/Loader/Loader');

	var data = path.resolve(__dirname + '/../data');
	var simpleModulePath = data + '/package/node_modules/module/index.js';
	var advancedModulePath = data + '/package/node_modules/module/node_modules/another_one/file.json';
	var invalidModule = data + '/some_file.js';

	var simq = new SimQ(false, data + '/package');
	var loader = new Loader(simq);

	var libraries = {
		list: [
			'./libs/begin/<[0-9]>.js',
			'./libs/begin/4.js',
			'./libs/begin/6.coffee',
			'./libs/begin/*.<(json|coffee)$>'
		],
		expected: [
			simq.basePath + '/libs/begin/1.js',
			simq.basePath + '/libs/begin/2.js',
			simq.basePath + '/libs/begin/3.js',
			simq.basePath + '/libs/begin/4.js',
			simq.basePath + '/libs/begin/5.json',
			simq.basePath + '/libs/begin/6.coffee'
		]
	};

	var modules = {
		list: [
			'./modules/<[0-9]>.js',
			'./modules/4.js',
			'./modules/6.coffee',
			'./modules/*.<(json|coffee)$>'
		],
		expected: [
			simq.basePath + '/modules/1.js',
			simq.basePath + '/modules/2.js',
			simq.basePath + '/modules/3.js',
			simq.basePath + '/modules/4.js',
			simq.basePath + '/modules/5.json',
			simq.basePath + '/modules/6.coffee'
		]
	};

	describe('ApplicationHelpers', function() {

		describe('#isInModule()', function() {
			it('should return true when file is in node modules', function() {
				ApplicationHelpers.isInModule(simpleModulePath).should.be.true;
				ApplicationHelpers.isInModule(advancedModulePath).should.be.true;
			});

			it('should return false when file is not in node modules', function() {
				ApplicationHelpers.isInModule(invalidModule).should.be.false;
			});
		});

		describe('#getModuleName()', function() {
			it('should return module name when file is in node module', function() {
				ApplicationHelpers.getModuleName(simpleModulePath).should.equal('module');
				ApplicationHelpers.getModuleName(advancedModulePath).should.equal('another_one');
			});

			it('should return null when file is not in node module', function() {
				should.not.exist(ApplicationHelpers.getModuleName(invalidModule));
			});
		});

		describe('#getModuleBaseDir()', function() {
			it('should return module directory for file if file is node module', function() {
				ApplicationHelpers.getModuleBaseDir(simpleModulePath).should.equal(data + '/package/node_modules/module');
				ApplicationHelpers.getModuleBaseDir(advancedModulePath).should.equal(data + '/package/node_modules/module/node_modules/another_one');
			});

			it('should return null if file is not in node module', function() {
				should.not.exist(ApplicationHelpers.getModuleBaseDir(invalidModule));
			});
		});

		describe('#findNodePackage()', function() {
			it('should return path to package.json file if file is in node module', function() {
				ApplicationHelpers.findNodePackage(simpleModulePath).should.equal(data + '/package/node_modules/module/package.json');
				ApplicationHelpers.findNodePackage(advancedModulePath).should.equal(data + '/package/node_modules/module/node_modules/another_one/package.json');
			});

			it('should return null if file is not in node module', function() {
				should.not.exist(ApplicationHelpers.findNodePackage(invalidModule));
			});
		});

		describe('#findPackageInfo()', function() {
			it('should return informations from parsed package.json if file is in node module', function() {
				ApplicationHelpers.findPackageInfo(simpleModulePath).should.eql({
					file: simq.basePath + '/node_modules/module/index.js',
					name: 'module',
					main: simq.basePath + '/node_modules/module/index.js',
					dir: simq.basePath + '/node_modules/module'
				});
				ApplicationHelpers.findPackageInfo(advancedModulePath).should.eql({
					file: simq.basePath + '/node_modules/module/node_modules/another_one/file.json',
					name: 'another_one',
					main: simq.basePath + '/node_modules/module/node_modules/another_one/something/index.json',
					dir: simq.basePath + '/node_modules/module/node_modules/another_one'
				});
			});

			it('should return null if file is not in node module', function() {
				should.not.exist(ApplicationHelpers.findPackageInfo(invalidModule));
			})
		});

		describe('#resolveNodeFile()', function() {
			it('should return expanded file path', function() {
				ApplicationHelpers.resolveNodeFile(data + '/package/node_modules/module/index').should.equal(data + '/package/node_modules/module/index.js');
				ApplicationHelpers.resolveNodeFile(data + '/package/node_modules/module/node_modules/another_one/something').should.equal(data + '/package/node_modules/module/node_modules/another_one/something/index.json');
			});

			it('should return null when expanded file was not found', function() {
				should.not.exist(ApplicationHelpers.resolveNodeFile(data + '/random_file'));
			});
		});

		describe('#removeDuplicates()', function() {
			it('should return array without duplicates', function() {
				ApplicationHelpers.removeDuplicates([1, 1, 1, 2, 2, 3, 1, 1, 2, 4, 6, 3, 4, 2]).should.eql([1, 2, 3, 4, 6]);
			});
		});

		describe('#findLibrariesFromList()', function() {
			it('should return list of resolved libraries', function() {
				ApplicationHelpers.findLibrariesFromList(libraries.list, simq.basePath).should.eql(libraries.expected);
			});
		});

		describe('#parseModulesList()', function() {
			it('should return list of resolved modules', function() {
				ApplicationHelpers.parseModulesList(modules.list, simq.basePath).should.eql(modules.expected);
			});
		});

		describe('#parseDependencies()', function() {
			it('should return list of dependencies from required module', function(done) {
				var dep = required(simq.basePath + '/modules/1.js', {ignoreMissing: true}, function(e, deps) {
					ApplicationHelpers.parseDependencies(deps[0]).should.eql({
						files: [
							simq.basePath + '/modules/2.js',
							simq.basePath + '/modules/3.js',
							simq.basePath + '/node_modules/module/index.js'
						],
						core: ['fs', 'path']
					});
					done();
				});
			});
		});

		describe('#findDependentModules()', function() {
			it('should return object with dependencies from given file', function(done) {
				ApplicationHelpers.findDependentModules(simq.basePath + '/modules/1.js').then(function(data) {
					var expect = {
						files: [
							simq.basePath + '/modules/1.js',
							simq.basePath + '/modules/2.js',
							simq.basePath + '/modules/3.js',
							simq.basePath + '/node_modules/module/index.js'
						],
						core: ['fs', 'path'],
						node: {}
					};
					expect.node[simq.basePath + '/node_modules/module'] = {
						name: 'module',
						main: '/var/www/node/simq/test/data/package/node_modules/module/index.js'
					};

					data.should.eql(expect);
					done();
				}).done();
			});
		});

		describe('#findDependentModulesFromList()', function() {
			it('should return object with informations for modules from modules list in configuration', function(done) {
				ApplicationHelpers.findDependentModulesFromList(modules.list, simq.basePath).then(function(data) {
					var expect = {
						files: [
							'/var/www/node/simq/test/data/package/modules/1.js',
							'/var/www/node/simq/test/data/package/modules/2.js',
							'/var/www/node/simq/test/data/package/modules/3.js',
							'/var/www/node/simq/test/data/package/node_modules/module/index.js',
							'/var/www/node/simq/test/data/package/modules/4.js',
							'/var/www/node/simq/test/data/package/modules/5.json',
							'/var/www/node/simq/test/data/package/modules/6.coffee'
						],
						core: ['fs', 'path'],
						node: {}
					};
					expect.node[simq.basePath + '/node_modules/module'] = {
						name: 'module',
						main: '/var/www/node/simq/test/data/package/node_modules/module/index.js'
					};

					data.should.eql(expect);
					done();
				}).done();
			});
		});

		describe('#loadModules()', function() {
			it('should return prepared module file', function(done) {
				ApplicationHelpers.loadModules(loader, [simq.basePath + '/modules/1.js'], simq.basePath).then(function(data) {
					var content = '\'data/package/modules/1.js\': function(exports, _r, module) {\nvar require = function(name) {return _r(name, \'data/package/modules/1.js\');};\nreturn (function() {\nrequire(\'./2\');\n}).call(this);\n};';
					data.should.eql([content]);
					done();
				}).done();
			});
		});

		describe('#loadLibraries()', function() {
			it('should return array with loaded libraries', function(done) {
				ApplicationHelpers.loadLibraries(loader, ['./libs/begin/*.js<$>'], simq.basePath).then(function(data) {
					data.should.eql(['// 1', '// 2', '// 3', '// 4']);
					done();
				}).done();
			});
		});

	});

})();