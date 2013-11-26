// Generated by CoffeeScript 1.6.3
(function() {
  var Commands, Compiler, Configurator, Factory, Finder, SimQ, commands, dir, expect, fs, http, path, rimraf, server, simq;

  expect = require('chai').expect;

  path = require('path');

  Finder = require('fs-finder');

  rimraf = require('rimraf');

  fs = require('fs');

  Compiler = require('source-compiler');

  http = require('http');

  SimQ = require('../../lib/SimQ');

  Commands = require('../../lib/Commands');

  Factory = require('../../lib/Package/Factory');

  Configurator = require('../../lib/Config/Configurator');

  dir = path.resolve(__dirname + '/../data');

  simq = null;

  commands = null;

  server = null;

  describe('Commands', function() {
    describe('#create()', function() {
      beforeEach(function() {
        simq = new SimQ(dir);
        return commands = new Commands(simq);
      });
      it('should throw an error if path already exists', function(done) {
        return commands.create('package').fail(function(err) {
          expect(err).to.be.an["instanceof"](Error);
          expect(err.message).to.be.equal('Directory package already exists.');
          return done();
        }).done();
      });
      it('should create new project from sandbox', function(done) {
        return commands.create('test').then(function() {
          var files;
          files = Finder.findFiles(dir + '/test/*');
          expect(files).to.be.eql([dir + '/test/config/setup.json', dir + '/test/css/style.less', dir + '/test/package.json', dir + '/test/public/application.js', dir + '/test/public/index.html', dir + '/test/public/style.css']);
          return rimraf(dir + '/test', function() {
            return done();
          });
        }).done();
      });
      return it('should build application from sandbox', function(done) {
        return commands.create('test').then(function() {
          var c, configurator, pckg, s;
          s = new SimQ(dir + '/test');
          c = new Commands(s);
          configurator = new Configurator(dir + '/test/config/setup.json');
          pckg = Factory.create(s.basePath, configurator.load().packages.application);
          s.addPackage('test', pckg);
          return c.build().then(function() {
            expect(fs.readFileSync(dir + '/test/public/application.js', {
              encoding: 'utf8'
            })).to.have.string("'/package.json'");
            expect(fs.readFileSync(dir + '/test/public/style.css', {
              encoding: 'utf8'
            })).to.be.equal('');
            return rimraf(dir + '/test', function() {
              return done();
            });
          }).done();
        }).done();
      });
    });
    describe('#clean()', function() {
      return it('should remove all files created by simq', function(done) {
        simq = new SimQ(dir);
        commands = new Commands(simq);
        return commands.create('test').then(function() {
          var c, configurator, pckg, s;
          s = new SimQ(dir + '/test');
          c = new Commands(s);
          configurator = new Configurator(dir + '/test/config/setup.json');
          pckg = Factory.create(s.basePath, configurator.load().packages.application);
          s.addPackage('test', pckg);
          return c.build().then(function() {
            fs.writeFileSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json', '{}');
            c.clean('../cache');
            expect(fs.existsSync(dir + '/test/public/application.js')).to.be["false"];
            expect(fs.existsSync(dir + '/test/public/style.css')).to.be["false"];
            expect(fs.existsSync(dir + '/cache/__' + Compiler.CACHE_NAMESPACE + '.json')).to.be["false"];
            return rimraf(dir + '/test', function() {
              return done();
            });
          }).done();
        }).done();
      });
    });
    return describe('#server()', function() {
      beforeEach(function() {
        simq = new SimQ(dir + '/package');
        return commands = new Commands(simq);
      });
      afterEach(function() {
        return server.close();
      });
      it('should create default server for application', function(done) {
        server = commands.server();
        return http.get('http://localhost:3000', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.have.string('Hello word');
            return done();
          });
        });
      });
      it('should create default server on another port', function(done) {
        server = commands.server(null, null, null, 8080);
        return http.get('http://localhost:8080', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.have.string('Hello word');
            return done();
          });
        });
      });
      it('should create server with prefix', function(done) {
        server = commands.server('package');
        return http.get('http://localhost:3000/package', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.have.string('Hello word');
            return done();
          });
        });
      });
      it('should create server with different main file', function(done) {
        server = commands.server(null, './public/default.html');
        return http.get('http://localhost:3000', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.have.string('Some default page');
            return done();
          });
        });
      });
      it('should create server with some route', function(done) {
        server = commands.server(null, null, {
          'jquery.js': './public/jquery.js'
        });
        return http.get('http://localhost:3000/jquery.js', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.be.equal('// This is not jQuery');
            return done();
          });
        });
      });
      it('should create server with route to directory', function(done) {
        server = commands.server(null, null, {
          'public': './public'
        });
        return http.get('http://localhost:3000/public/jquery.js', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.be.equal('// This is not jQuery');
            return done();
          });
        });
      });
      it('should create server with route to directory and prefix', function(done) {
        server = commands.server('package', null, {
          'public': './public'
        });
        return http.get('http://localhost:3000/package/public/jquery.js', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.be.equal('// This is not jQuery');
            return done();
          });
        });
      });
      it('should create server with package (js)', function(done) {
        var pckg;
        pckg = simq.addPackage('app');
        pckg.setApplication('./public/application.js');
        pckg.addModule('./app/Application.coffee');
        server = commands.server();
        return http.get('http://localhost:3000/public/application.js', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.have.string("'/app/Application.coffee'");
            return done();
          });
        });
      });
      it('should create server with package (js) and prefix', function(done) {
        var pckg;
        pckg = simq.addPackage('app');
        pckg.setApplication('./public/application.js');
        pckg.addModule('./app/Application.coffee');
        server = commands.server('package');
        return http.get('http://localhost:3000/package/public/application.js', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.have.string("'/app/Application.coffee'");
            return done();
          });
        });
      });
      it('should create server with package (css)', function(done) {
        var pckg;
        pckg = simq.addPackage('app');
        pckg.setStyle('./css/style.less', './public/style.css');
        server = commands.server();
        return http.get('http://localhost:3000/public/style.css', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.be.equal('body {\n  color: #000000;\n}\n');
            return done();
          });
        });
      });
      it('should create server with package (css) and prefix', function(done) {
        var pckg;
        pckg = simq.addPackage('app');
        pckg.setStyle('./css/style.less', './public/style.css');
        server = commands.server('package');
        return http.get('http://localhost:3000/package/public/style.css', function(res) {
          var data;
          data = [];
          res.setEncoding('utf8');
          res.on('data', function(chunk) {
            return data.push(chunk);
          });
          return res.on('end', function() {
            data = data.join('');
            expect(data).to.be.equal('body {\n  color: #000000;\n}\n');
            return done();
          });
        });
      });
      it('should create server from sandbox (main)', function(done) {
        var c, s;
        s = new SimQ(dir);
        c = new Commands(s);
        return c.create('test').then(function() {
          var configurator, pckg;
          simq = new SimQ(dir + '/test');
          commands = new Commands(simq);
          configurator = new Configurator(dir + '/test/config/setup.json');
          pckg = Factory.create(simq.basePath, configurator.load().packages.application);
          simq.addPackage('test', pckg);
          server = commands.server();
          return http.get('http://localhost:3000', function(res) {
            var data;
            data = [];
            res.setEncoding('utf8');
            res.on('data', function(chunk) {
              return data.push(chunk);
            });
            return res.on('end', function() {
              data = data.join('');
              expect(data).to.have.string('<!-- your content -->');
              return rimraf(dir + '/test', function() {
                return done();
              });
            });
          });
        }).done();
      });
      it('should create server from sandbox (js)', function(done) {
        var c, s;
        s = new SimQ(dir);
        c = new Commands(s);
        return c.create('test').then(function() {
          var configurator, pckg;
          simq = new SimQ(dir + '/test');
          commands = new Commands(simq);
          configurator = new Configurator(dir + '/test/config/setup.json');
          pckg = Factory.create(simq.basePath, configurator.load().packages.application);
          simq.addPackage('test', pckg);
          server = commands.server();
          return http.get('http://localhost:3000/public/application.js', function(res) {
            var data;
            data = [];
            res.setEncoding('utf8');
            res.on('data', function(chunk) {
              return data.push(chunk);
            });
            return res.on('end', function() {
              data = data.join('');
              expect(data).to.have.string("'/package.json'");
              return rimraf(dir + '/test', function() {
                return done();
              });
            });
          });
        }).done();
      });
      return it('should create server from sandbox (css)', function(done) {
        var c, s;
        s = new SimQ(dir);
        c = new Commands(s);
        return c.create('test').then(function() {
          var configurator, pckg;
          simq = new SimQ(dir + '/test');
          commands = new Commands(simq);
          configurator = new Configurator(dir + '/test/config/setup.json');
          pckg = Factory.create(simq.basePath, configurator.load().packages.application);
          simq.addPackage('test', pckg);
          server = commands.server();
          return http.get('http://localhost:3000/public/style.css', function(res) {
            var data;
            data = [];
            res.setEncoding('utf8');
            res.on('data', function(chunk) {
              return data.push(chunk);
            });
            return res.on('end', function() {
              data = data.join('');
              expect(data).to.be.equal('');
              return rimraf(dir + '/test', function() {
                return done();
              });
            });
          });
        }).done();
      });
    });
  });

}).call(this);
