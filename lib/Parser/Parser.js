// Generated by CoffeeScript 1.6.3
(function() {
  var Application, Loader, Parser, Q, Style;

  Q = require('q');

  Application = require('./Application');

  Style = require('./Style');

  Loader = require('../Loader/Loader');

  Parser = (function() {
    Parser.prototype.simq = null;

    Parser.prototype.loader = null;

    Parser.prototype.basePath = null;

    function Parser(simq, basePath) {
      this.simq = simq;
      this.basePath = basePath;
      this.loader = new Loader(this.simq);
    }

    Parser.prototype.parseApplication = function(section, minify) {
      if (minify == null) {
        minify = true;
      }
      return (new Application(this.simq, this.loader, this.basePath)).parse(section, minify);
    };

    Parser.prototype.parseStyle = function(path, minify) {
      if (minify == null) {
        minify = true;
      }
      return (new Style(this.basePath)).parse(path, minify);
    };

    return Parser;

  })();

  module.exports = Parser;

}).call(this);