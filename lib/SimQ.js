(function() {

	var SimQ, fs, uglify, coffee;

	fs = require('fs');
	uglify = require('uglify-js');
	coffee = require('coffee-script');

	SimQ = (function() {

		SimQ.prototype.basePath = '.';

		SimQ.prototype.config = null;

		SimQ.prototype.supported = ['js', 'coffee'];

		function SimQ() {

		};

		SimQ.prototype.build = function(minify) {
			var config, result;

			if (minify === null) {
				minify = true;
			}

			console.log('Building application');

			config = this.getConfig(this.basePath + '/' + 'setup.json');

			result = this.parse();
			if (minify === true) {
				result = this.minify(result);
				console.log(result);
			}

			fs.writeFileSync(this.basePath + '/' + config.main, result);
		};

		SimQ.prototype.watch = function(minify) {
			var _this;

			_this = this;

			this.build(minify);

			require('watch').watchTree('.', function(file, curr, prev) {
				if (curr && (curr.nlink === 0 || + curr.mtime !== + (prev != null ? prev.mtime : void 0))) {
					_this.build(minify);
				}
			});
		};

		SimQ.prototype.parse = function() {
			var result, i, j, name, lib, files, file, supported, extension;

			supported = new RegExp('\\*\\.(' + this.supported.join('|') + ')$', 'i');
			extension = null;
			result = new Array;

			result.push(this.loadLibrary(__dirname + '/Module.js'));

			if (this.config.libs && this.config.libs.begin) {
				result = result.concat(this.getLibraries(this.config.libs.begin));
			}

			if (this.config.modules) {
				for (i in this.config.modules) {
					name = this.config.modules[i];

					if (name.match(supported)) {
						extension = name.match(supported)[1];
						name = name.replace(supported, '');
					}

					if (name.substr(name.length - 1) === '/') {
						result = result.concat(this.getModules(this.basePath + '/' + name, extension));
						extension = null;
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

		SimQ.prototype.minify = function(s) {
			return uglify.minify(s, {
				fromString: true
			}).code;
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
			var lib, supported;

			lib = this.loadLibrary(name);

			if (lib.substr(lib.length - 1) === ';') {
				lib = lib.substring(0, lib.length - 1);
			}

			lib = lib.replace(/\n/g, '\n\t');
			lib = '\t' + lib;

			if (name.substr(0, this.basePath.length) === this.basePath) {
				name = name.substring(this.basePath.length);
			}

			supported = new RegExp('\\.(' + this.supported.join('|') + ')$', 'i');
			name = name.replace(/^[./]+/, '').replace(supported, '');
			return 'this.Module.register(\'' + name + '\',\n' + lib + '\n);';
		};

		SimQ.prototype.getModules = function(dirName, extension) {
			var files, i, name, lib, result, stats, ext;

			files = fs.readdirSync(dirName);
			result = new Array;

			for (i in files) {
				name = dirName + files[i];
				stats = fs.statSync(name);

				if (stats.isFile() && name.substring(name.length - 1) !== '~') {
					if (extension) {
						ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase();
						if (ext !== extension) {
							continue;
						}
					}

					result.push(this.getModule(name));
				} else if (stats.isDirectory()) {
					result = result.concat(this.getModules(name + '/', extension));
				}
			}

			return result;
		};

		SimQ.prototype.loadLibrary = function(path) {
			var file, extension;

			file =  fs.readFileSync(path).toString();
			extension = path.substring(path.lastIndexOf('.') + 1).toLowerCase();

			if (this.supported.indexOf(extension) === -1) {
				return '';
			}

			switch (extension) {
				case 'js': break;
				case 'coffee': file = coffee.compile(file); break;
			}

			file = file.replace(/^\s+|\s+$/g, '');
			return file;
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