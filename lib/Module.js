(function() {

	this.Module = {

		modules: {},

		register: function(path, lib) {
			this.modules[path] = lib;
		},

		require: function(path) {
			return this.modules[path];
		}

	};

	this.require = function(path) {
		return this.Module.require(path);
	};

}).call(this);