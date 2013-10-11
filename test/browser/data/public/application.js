/** Generated by SimQ **/
/** modules **/

// Generated by CoffeeScript 1.6.3
(function() {
  var SUPPORTED, cache, modules, require, resolve;

  if (!this.require) {
    SUPPORTED = ['js', 'json', 'ts', 'coffee'];
    modules = {};
    cache = {};
    require = function(name, parent) {
      var fullName, m;
      if (parent == null) {
        parent = null;
      }
      fullName = resolve(name, parent);
      if (fullName === null) {
        throw new Error('Module ' + name + ' was not found.');
      }
      if (typeof cache[fullName] === 'undefined') {
        m = {
          exports: {},
          id: fullName,
          filename: fullName,
          loaded: false,
          parent: null,
          children: null
        };
        modules[fullName].apply(modules[fullName], [m.exports, m]);
        m.loaded = true;
        cache[fullName] = m;
      }
      return cache[fullName].exports;
    };
    resolve = function(name, parent) {
      var ext, num, part, parts, prev, result, _i, _j, _k, _len, _len1, _len2;
      if (parent == null) {
        parent = null;
      }
      if (parent !== null && name[0] !== '/') {
        num = parent.lastIndexOf('/');
        if (num !== -1) {
          parent = parent.substr(0, num);
        }
        name = parent + '/' + name;
        parts = name.split('/');
        result = [];
        prev = null;
        for (_i = 0, _len = parts.length; _i < _len; _i++) {
          part = parts[_i];
          if (part === '.' || part === '') {
            continue;
          } else if (part === '..' && prev) {
            result.pop();
          } else {
            result.push(part);
          }
          prev = part;
        }
        name = '/' + result.join('/');
      }
      if (typeof modules[name] !== 'undefined') {
        return name;
      }
      for (_j = 0, _len1 = SUPPORTED.length; _j < _len1; _j++) {
        ext = SUPPORTED[_j];
        if (typeof modules[name + '.' + ext] !== 'undefined') {
          return name + '.' + ext;
        }
      }
      for (_k = 0, _len2 = SUPPORTED.length; _k < _len2; _k++) {
        ext = SUPPORTED[_k];
        if (typeof modules[name + '/index.' + ext] !== 'undefined') {
          return name + '/index.' + ext;
        }
      }
      return null;
    };
    this.require = function(name, parent) {
      if (parent == null) {
        parent = null;
      }
      return require(name, parent);
    };
    this.require.resolve = function(name, parent) {
      if (parent == null) {
        parent = null;
      }
      return resolve(name, parent);
    };
    this.require.define = function(bundle) {
      var m, name, _results;
      _results = [];
      for (name in bundle) {
        m = bundle[name];
        _results.push(modules[name] = m);
      }
      return _results;
    };
    this.require.release = function() {
      var name, _results;
      _results = [];
      for (name in cache) {
        _results.push(delete cache[name]);
      }
      return _results;
    };
    this.require.cache = cache;
  }

  return this.require.define;

}).call(this)({
'/app/Application.coffee': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, '/app/Application.coffee');};
	require.resolve = function(name, parent) {if (parent === null) {parent = '/app/Application.coffee';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = '/app/Application.coffee';
	var __dirname = '/app';
	var process = {cwd: function() {return '/';}, argv: ['node', '/app/Application.coffee'], env: {}};

	/** code **/
	(function() {
	  module.exports = 'Application';
	
	}).call(this);
	

},'/app/Bootstrap.coffee': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, '/app/Bootstrap.coffee');};
	require.resolve = function(name, parent) {if (parent === null) {parent = '/app/Bootstrap.coffee';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = '/app/Bootstrap.coffee';
	var __dirname = '/app';
	var process = {cwd: function() {return '/';}, argv: ['node', '/app/Bootstrap.coffee'], env: {}};

	/** code **/
	(function() {
	  require('');
	
	}).call(this);
	

},'/test/Require.coffee': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, '/test/Require.coffee');};
	require.resolve = function(name, parent) {if (parent === null) {parent = '/test/Require.coffee';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = '/test/Require.coffee';
	var __dirname = '/test';
	var process = {cwd: function() {return '/';}, argv: ['node', '/test/Require.coffee'], env: {}};

	/** code **/
	(function() {
	  var require;
	
	  require = window.require;
	
	  describe('require', function() {
	    beforeEach(function() {
	      return require.release();
	    });
	    afterEach(function() {
	      return require.release();
	    });
	    describe('#resolve()', function() {
	      it('should return same name for module', function() {
	        return expect(require.resolve('/app/Application.coffee')).to.be.equal('/app/Application.coffee');
	      });
	      it('should return name of module without extension', function() {
	        return expect(require.resolve('/app/Application')).to.be.equal('/app/Application.coffee');
	      });
	      it('should return name of module from parent', function() {
	        return expect(require.resolve('./Application.coffee', '/app/Bootstrap.coffee')).to.be.equal('/app/Application.coffee');
	      });
	      it('should return name of module from parent without extension', function() {
	        return expect(require.resolve('./Application', '/app/Bootstrap.coffee')).to.be.equal('/app/Application.coffee');
	      });
	      it('should resolve name in root directory', function() {
	        return expect(require.resolve('/setup.js')).to.be.equal('/setup.js');
	      });
	      it('should resolve name in root without extension', function() {
	        return expect(require.resolve('/setup')).to.be.equal('/setup.js');
	      });
	      it('should resolve name for main file', function() {
	        return expect(require.resolve('/index.js')).to.be.equal('/index.js');
	      });
	      it('should resolve name for main file without extension', function() {
	        return expect(require.resolve('/index')).to.be.equal('/index.js');
	      });
	      it('should resolve name for package file', function() {
	        return expect(require.resolve('/package.json')).to.be.equal('/package.json');
	      });
	      return it('should resolve name for package file withoud extension', function() {
	        return expect(require.resolve('/package')).to.be.equal('/package.json');
	      });
	    });
	    describe('#require()', function() {
	      it('should load simple module', function() {
	        return expect(require('/app/Application.coffee')).to.be.equal('Application');
	      });
	      it('should load simple module without extension', function() {
	        return expect(require('/app/Application')).to.be.equal('Application');
	      });
	      it('should load package file', function() {
	        var data;
	        data = require('/package');
	        expect(data).to.include.keys(['name']);
	        return expect(data.name).to.be.equal('browser-test');
	      });
	      it('should load package from alias', function() {
	        return expect(require('app')).to.be.equal('Application');
	      });
	      it('should load npm module', function() {
	        return expect(require('any')).to.be.equal('hello');
	      });
	      return it('should load package file from npm module', function() {
	        var data;
	        data = require('any/package');
	        expect(data).to.include.keys(['name']);
	        return expect(data.name).to.be.equal('any');
	      });
	    });
	    return describe('cache', function() {
	      it('should be empty', function() {
	        return expect(require.cache).to.be.eql({});
	      });
	      return it('should contain required module', function() {
	        require('/app/Application');
	        return expect(require.cache).to.include.keys(['/app/Application.coffee']);
	      });
	    });
	  });
	
	}).call(this);
	

},'/setup.js': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, '/setup.js');};
	require.resolve = function(name, parent) {if (parent === null) {parent = '/setup.js';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = '/setup.js';
	var __dirname = '/';
	var process = {cwd: function() {return '/';}, argv: ['node', '/setup.js'], env: {}};

},'/package.json': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, '/package.json');};
	require.resolve = function(name, parent) {if (parent === null) {parent = '/package.json';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = '/package.json';
	var __dirname = '/';
	var process = {cwd: function() {return '/';}, argv: ['node', '/package.json'], env: {}};

	/** code **/
	module.exports = (function() {
	return {
		"name": "browser-test",
		"version": "1.0.0",
		"dependencies": {
			"any": "latest"
		}
	}
	}).call(this);
	

},'/index.js': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, '/index.js');};
	require.resolve = function(name, parent) {if (parent === null) {parent = '/index.js';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = '/index.js';
	var __dirname = '/';
	var process = {cwd: function() {return '/';}, argv: ['node', '/index.js'], env: {}};

},'any/package.json': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, 'any/package.json');};
	require.resolve = function(name, parent) {if (parent === null) {parent = 'any/package.json';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = 'any/package.json';
	var __dirname = 'any';
	var process = {cwd: function() {return '/';}, argv: ['node', 'any/package.json'], env: {}};

	/** code **/
	module.exports = (function() {
	return {
		"name": "any",
		"version": "1.0.0"
	}
	}).call(this);
	

},'any': function(exports, module) {

	/** node globals **/
	var require = function(name) {return window.require(name, 'any');};
	require.resolve = function(name, parent) {if (parent === null) {parent = 'any';} return window.require.resolve(name, parent);};
	require.define = function(bundle) {window.require.define(bundle);};
	require.cache = window.require.cache;
	var __filename = 'any';
	var __dirname = '.';
	var process = {cwd: function() {return '/';}, argv: ['node', 'any'], env: {}};

	/** code **/
	module.exports = 'hello';

},'app': function(exports, module) { module.exports = window.require('/app/Application'); }
});

/** run section **/

require('/test/Require');