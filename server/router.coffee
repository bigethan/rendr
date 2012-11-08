# Functions for getting Controllers and Actions.
mw = require('./middleware')
_ = require('underscore')
routes = require(rendr.entryPath + '/routes')

# given a name, eg "listings#show"
# return function that matches that controller's action (eg the show method of the listings controller)
getAction = (config) ->
  controller = getController(config.controller);
  controller[config.action]

getController = (controllerName) ->
  require(rendr.entryPath + "/controllers/#{controllerName}_controller")

getHandler = (action) ->
  (req, res, next) ->
    context =
      app: req.appContext
      redirectTo: (url) -> res.redirect(url)

    params = req.query || {}
    req.route.keys.forEach (routeKey) ->
      params[routeKey.name] = req.route.params[routeKey.name]

    action.call context, params, (err, template, data) ->
      return handleErr(err, req, res) if err
      res.render(template, locals: data, app: req.appContext, req: req)

handleErr = (err, req, res) ->
  # stash rndr in request for propper middleware logging
  if (!req.rndr) 
    req.rndr = {}
  req.rndr.err = err

  if err.statusCode && err.statusCode is 401
    res.redirect('/login')
  else
    # Throw the error, let Express catch it.
    throw err
    # res.redirect('/error')
    # res.send(err.statusCode || 500)

getAuthenticate = (routeInfo) ->
  (req, res, next) ->
    if routeInfo.authenticated && false # !req.appContext.SessionManager.loggedIn()
      res.redirect('/login')
    else
      next()

# Attach our routes to our server
exports.buildRoutes = (server) ->
  for own path, routeInfo of routes
    action = getAction(routeInfo)
    handler = getHandler(action)
    authenticate = getAuthenticate(routeInfo)

    server.get("/#{path}", authenticate, handler)
