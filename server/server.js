var router = require('./router');
var viewEngine = require('./view_engine');
var env = require('../config/environments/env');
var assetCompiler = require('./lib/assetCompiler');

exports.dataAdapter = null;


// ===== VIEWS =====

exports.viewConfig =  {
  engineName: 'coffee',
  engine: viewEngine.engine,
  viewDir: env.paths.viewDir,
  publicDir: env.paths.publicDir,
  apiPath:'/api'
};


// ===== ROUTES =====

exports.routes = function() {
  return router.routes();
};


// ===== MIDDLEWARE =====

var createAppInstance = function() {
  return function(req, res, next) {
    var App = require(env.paths.entryPath + "/app");  // moweb/app/app.coffee
    req.appContext = new App;
    next();
  };
};


exports.middleware = function() {
  return [ createAppInstance() ];
};


// ===== LIBRARIES =====

/**
  - options
    - logger
    - dataAdapter
*/
exports.initLibs = function(options, callback) {
  if (!options) options = {};

  // pass down stashError and stashPerf to router
  router.init(options);

  exports.dataAdapter = options.dataAdapter;

  if (env.current.assetCompiler && env.current.assetCompiler.enabled) {
    assetCompiler.init(env.current.assetCompiler, options.logger, function(err) {
      if (err) return callback(err);
      assetCompiler.compile(callback);
    });
  } else {
    callback();
  }
};

exports.closeLibs = function(callback) {
  callback();
};

