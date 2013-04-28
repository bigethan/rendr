var BaseRouter, ServerRouter, sanitize, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require('underscore');
BaseRouter = require('../shared/base/router');
sanitize = require('validator').sanitize;

module.exports = ServerRouter = (function(_super) {
  __extends(ServerRouter, _super);

  function ServerRouter() {
    ServerRouter.__super__.constructor.apply(this, arguments);
  }

  ServerRouter.prototype.escapeParams = function(params) {
    var escaped = {};
    _.each(params, function(value, key) {
      escaped[key] = sanitize(value).xss();
    });
    return escaped;
  };

  /*
  * This is the method that renders the request. It returns an Express
  * middleware function.
  */
  ServerRouter.prototype.getHandler = function(action, pattern, route) {
    var router = this;

    return function(req, res, next) {
      var app, context, params;

      app = req.rendrApp;
      context = {
        currentRoute: route,
        app: app,
        redirectTo: function(url) {
          res.redirect(url);
        }
      };
      params = req.query || {};
      req.route.keys.forEach(function(routeKey) {
        params[routeKey.name] = req.route.params[routeKey.name];
      });
      params = router.escapeParams(params);
      action.call(context, params, function(err, template, locals) {
        var viewData;

        if (err) {
          return router.handleErr(err, req, res);
        }
        viewData = {
          locals: locals,
          app: app,
          req: req
        };
        res.render(template, viewData, function(err, html) {
          if (err) {
            return router.handleErr(err, req, res);
          }
          res.set(router.getHeadersForRoute(route));
          res.type('html').end(html);
        });
      });
    };
  };

  /*
  * Handle an error that happens while executing an action.
  * Could happen during the controller action, view rendering, etc.
  */
  ServerRouter.prototype.handleErr = function(err, req, res) {
    var text;

    this.stashError(req, err);
    if (this.options.errorHandler) {
      this.options.errorHandler(err, req, res);
    } else {
      if (this.options.dumpExceptions) {
        text = "Error: " + err.message + "\n";
        if (err.stack) {
          text += "\nStack:\n " + err.stack;
        }
      } else {
        text = "500 Internal Server Error";
      }
      res.status(err.status || 500);
      res.type('text').send(text);
    }
  };

  ServerRouter.prototype.getHeadersForRoute = function(definition) {
    var headers = {};
    if (definition.maxAge != null) {
      headers['Cache-Control'] = "public, max-age=" + definition.maxAge;
    }
    return headers;
  };

  /*
  * stash error, if handler available
  */
  ServerRouter.prototype.stashError = function(req, err) {
    if (this.options.stashError != null) {
      this.options.stashError(req, err);
    }
  };

  /*
  * We create and reuse an instance of Express Router in 'this.match()'.
  */
  ServerRouter.prototype._expressRouter = null;

  /*
  * Return the route definition based on a URL, according to the routes file.
  * This should match the way Express matches routes on the server, and our
  * ClientRouter matches routes on the client.
  */


  ServerRouter.prototype.match = function(pathToMatch) {
    var Router, matchedRoute, path, routes, routesByPath,
        _this = this;

    if (~pathToMatch.indexOf('://')) {
      throw new Error('Cannot match full URL: "' + pathToMatch + '". Use pathname instead.');
    }

    routes = this.routes();
    routesByPath = {};

    /*
    * NOTE: Potential here to cache this work. Must invalidate when additional
    * routes are added.
    */
    Router = require('express').Router;
    this._expressRouter = new Router();
    _.each(routes, function(route) {
      // Add the route to the Express router, so we can use its matching logic
      // without attempting to duplicate it.
      path = route[0];
      _this._expressRouter.route('get', path, []);
      routesByPath[path] = route;
    });

    // Ensure leading slash
    if (pathToMatch.slice(0, 1) !== '/') {
      pathToMatch = "/" + pathToMatch;
    }
    matchedRoute = this._expressRouter.match('get', pathToMatch);
    if (matchedRoute == null) {
      return null;
    }
    return routesByPath[matchedRoute.path];
  };

  return ServerRouter;

})(BaseRouter);
