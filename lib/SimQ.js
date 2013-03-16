(function() {

	var SimQ, fs;

	fs = require('fs');

	SimQ = (function() {

		SimQ.prototype.basePath = '.';

		SimQ.prototype.config = null;

		function SimQ() {

		};

		SimQ.prototype.build = function() {
			var config, result;

			console.log('Building application');

			config = this.getConfig(this.basePath + '/' + 'setup.json');

			result = this.parse();

			fs.writeFileSync(this.basePath + '/' + config.main, result);
		};

		SimQ.prototype.watch = function() {
			var _this;

			_this = this;

			this.build();

			require('watch').watchTree('.', function(file, curr, prev) {
				if (curr && (curr.nlink === 0 || + curr.mtime !== + (prev != null ? prev.mtime : void 0))) {
					_this.build();
				}
			});
		};

		SimQ.prototype.parse = function() {
			var result, i, j, name, lib, files, file;

			result = new Array;

			result.push(this.loadLibrary(__dirname + '/Module.js'));

			if (this.config.libs && this.config.libs.begin) {
				result = result.concat(this.getLibraries(this.config.libs.begin));
			}

			if (this.config.modules) {
				for (i in this.config.modules) {
					name = this.config.modules[i];

					if (name.substr(name.length - 1) === '*') {
						name = name.substr(0, name.length - 1);

						result = result.concat(this.getModules(this.basePath + '/' + name));
					} else {
						result.push(this.getModule(this.basePath + '/' + name));
					}
				}
			}

			if (this.config.libs && this.config.libs.end) {
				result = result.concat(this.getLibraries(this.config.libs.end));
			}

			result = result.join('\n\n');

			return result;
		};

		SimQ.prototype.getLibraries = function(names) {
			var result, lib;

			result = new Array;

			for (i in names) {
				lib = names[i];

				result.push(this.loadLibrary(this.basePath + '/' + lib));
			}

			return result;
		};

		SimQ.prototype.getModule = function(name) {
			var lib;

			lib = this.loadLibrary(name);

			if (lib.substr(lib.length - 1) === ';') {
				lib = lib.substring(0, lib.length - 1);
			}

			lib = lib.replace(/\n/g, '\n\t');
			lib = '\t' + lib;

			if (name.substr(0, this.basePath.length) === this.basePath) {
				name = name.substring(this.basePath.length);
			}

			name = name.replace(/^[./]+/, '').replace(/\.js$/, '');
			return 'this.Module.register(\'' + name + '\',\n' + lib + '\n);';
		};

		SimQ.prototype.getModules = function(dirName) {
			var files, i, name, lib, result;

			files = fs.readdirSync(dirName);
			result = new Array;

			for (i in files) {
				name = dirName + files[i];

				if (fs.statSync(name).isFile()) {
					result.push(this.getModule(name));
				} else {
					result = result.concat(this.getModules(name + '/'));
				}
			}

			return result;
		};

		SimQ.prototype.loadLibrary = function(path) {
			return fs.readFileSync(path).toString().replace(/^\s+|\s+$/g, '');
		};

		SimQ.prototype.getConfig = function(path) {
			if (!this.config) {
				if (!fs.existsSync(path)) {
					throw new Error(path + ' file was not found.');
				}

				this.config = JSON.parse(fs.readFileSync(path));
			}
			return this.config;
		}

		return SimQ;

	})();

	module.exports = SimQ;

}).call(this);