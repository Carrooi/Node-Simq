// Generated by CoffeeScript 1.6.3
(function() {
  var Package, SimQ, dir, expect, fs, path, simq;

  expect = require('chai').expect;

  path = require('path');

  fs = require('fs');

  SimQ = require('../../../lib/SimQ');

  Package = require('../../../lib/Package/Package');

  dir = path.resolve(__dirname + '/../../data/package');

  simq = null;

  describe('SimQ', function() {
    beforeEach(function() {
      return simq = new SimQ(dir);
    });
    describe('#addPackage()', function() {
      it('should add new instance of Package class', function() {
        simq.addPackage('test');
        expect(simq.packages).to.include.keys('test');
        return expect(simq.packages.test).to.be.an["instanceof"](Package);
      });
      it('should throw an error if package is already added', function() {
        simq.addPackage('test');
        return expect(function() {
          return simq.addPackage('test');
        }).to["throw"](Error);
      });
      it('should add new package directly', function() {
        var pckg;
        pckg = new Package(dir);
        simq.addPackage('test', pckg);
        expect(simq.hasPackage('test')).to.be["true"];
        return expect(simq.getPackage('test')).to.be.equal(pckg);
      });
      return it('should throw an error if package to add is not an instance of Package/Package', function() {
        return expect(function() {
          return simq.addPackage('test', new Array);
        }).to["throw"](Error, 'Package test must be an instance of Package/Package.');
      });
    });
    describe('#hasPackage()', function() {
      it('should return false', function() {
        return expect(simq.hasPackage('test')).to.be["false"];
      });
      return it('should return true', function() {
        simq.addPackage('test');
        return expect(simq.hasPackage('test')).to.be["true"];
      });
    });
    describe('#getPackage()', function() {
      it('should return instance of created package', function() {
        simq.addPackage('test');
        return expect(simq.getPackage('test')).to.be.an["instanceof"](Package);
      });
      return it('should throw an error if package is not registered', function() {
        return expect(function() {
          return simq._getPackage('test');
        }).to["throw"](Error);
      });
    });
    describe('#removePackage()', function() {
      it('should remove registered package', function() {
        simq.addPackage('test');
        simq.removePackage('test');
        return expect(simq.packages).not.to.include.keys('test');
      });
      return it('should throw an error if package is not registered', function() {
        return expect(function() {
          return simq.removePackage('test');
        }).to["throw"](Error);
      });
    });
    describe('#build()', function() {
      return it('should build all sections', function(done) {
        var pckg;
        pckg = simq.addPackage('test');
        pckg.addModule('./modules/1.js');
        pckg.addToAutorun('/modules/1');
        pckg.addToAutorun('- ./libs/begin/4.js');
        return simq.build().then(function(data) {
          expect(data).to.include.keys(['test']);
          expect(data.test).to.include.keys(['css', 'js']);
          expect(data.test.js).to.have.string("'/modules/2.js'");
          expect(data.test.js).to.have.string("'/modules/3.js'");
          expect(data.test.js).to.have.string("'module'");
          expect(data.test.js).to.have.string("require('/modules/1');");
          expect(data.test.js).to.have.string('// 4');
          return done();
        }).done();
      });
    });
    return describe('#buildToFiles()', function() {
      afterEach(function() {
        if (fs.existsSync(dir + '/public/application.js')) {
          return fs.unlinkSync(dir + '/public/application.js');
        }
      });
      return it('should build sections to files', function(done) {
        var pckg;
        pckg = simq.addPackage('test');
        pckg.addModule('./modules/1.js');
        pckg.addToAutorun('/modules/1');
        pckg.addToAutorun('- ./libs/begin/4.js');
        pckg.setTarget('public/application.js');
        return simq.buildToFiles().then(function(data) {
          data = fs.readFileSync(dir + '/public/application.js', {
            encoding: 'utf8'
          });
          expect(data).to.have.string("'/modules/2.js'");
          expect(data).to.have.string("'/modules/3.js'");
          expect(data).to.have.string("'module'");
          expect(data).to.have.string("require('/modules/1');");
          expect(data).to.have.string('// 4');
          return done();
        }).done();
      });
    });
  });

}).call(this);
