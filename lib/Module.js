(function() {

	this.Module = {

		modules: {},

		register: function(path, lib) {
			this.modules[path] = lib;
		},

		require: function(path) {
			if (typeof this.modules[path] === 'undefined') {
				throw new Error('Module ' + path + ' was not found');
			}
			return this.modules[path].call(this);
		}

	};

	this.require = function(path) {
		return this.Module.require(path);
	};

}).call(this);