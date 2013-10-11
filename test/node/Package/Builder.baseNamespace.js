// Generated by CoffeeScript 1.6.3
(function() {
  var Builder, Info, Package, builder, dir, expect, path, pckg;

  expect = require('chai').expect;

  path = require('path');

  Info = require('module-info');

  Package = require('../../../lib/Package/Package');

  Builder = require('../../../lib/Package/Builder');

  dir = path.resolve(__dirname + '/../../data/package');

  pckg = null;

  builder = null;

  describe('Package/Builder.baseNamespace', function() {
    beforeEach(function() {
      pckg = new Package(path.resolve(dir + '/../..'));
      pckg.base = 'data/package';
      return builder = new Builder(pckg);
    });
    describe('#buildModules()', function() {
      return it('should build one module from absolute path', function(done) {
        pckg.addModule(dir + '/modules/1.js');
        return builder.buildModules().then(function(data) {
          expect(data).to.have.string("'/modules/2.js'");
          expect(data).to.have.string("'/modules/3.js'");
          expect(data).to.have.string("'module'");
          return done();
        }).done();
      });
    });
    describe('#buildAutorun()', function() {
      return it('should build autorun section', function(done) {
        pckg.addModule('./modules/1.js');
        pckg.addToAutorun('/modules/1');
        pckg.addToAutorun('- ./libs/begin/4.js');
        return builder.buildAutorun().then(function(data) {
          expect(data).to.be.equal(["require('/modules/1');", '// 4'].join('\n'));
          return done();
        }).done();
      });
    });
    return describe('#build()', function() {
      return it('should build whole section', function(done) {
        pckg.addModule('./modules/1.js');
        pckg.addToAutorun('/modules/1');
        pckg.addToAutorun('- ./libs/begin/4.js');
        return builder.build().then(function(data) {
          expect(data).to.include.keys(['css', 'js']);
          expect(data.js).to.have.string("'/modules/2.js'");
          expect(data.js).to.have.string("'/modules/3.js'");
          expect(data.js).to.have.string("'module'");
          expect(data.js).to.have.string("require('/modules/1');");
          expect(data.js).to.have.string('// 4');
          return done();
        }).done();
      });
    });
  });

}).call(this);
