module.exports = class Router

  ##
  # Config
  #   - errorHandler: function to correctly handle error
  #   - paths
  #     - entryPath (required)
  #     - routes (optional)
  #     - controllerDir (optional)
  #   - stashPerf: optional function to store performance stats
  #   - stashError: optional function to notify server of error
  ##
  config: null

  # Internally stored route definitions.
  _routes: null

  constructor: (config, callback) ->
    @_routes = []
    @initialize(config, callback)

  initialize: (config, callback) ->
    @config = config || {}
    @config.paths ||= {}
    callback ||= ->

    if !config.paths.entryPath
      return callback(new Error("Missing entryPath"))
    config.paths.routes ||= config.paths.entryPath + '/routes'
    config.paths.controllerDir ||= config.paths.entryPath + '/controllers'
    callback()

  getController: (controllerName) ->
   require("#{@config.paths.controllerDir}/#{controllerName}_controller")

  # Given an object with 'controller' and 'action' properties,
  # return the corresponding action function.
  getAction: (spec) ->
    controller = @getController(spec.controller)
    controller[spec.action]

  # This is the method that renders the request.
  getHandler: (action, routeInfo) ->
    router = @

    (req, res, next) ->
      context =
        app: req.rendrApp
        redirectTo: (url) -> res.redirect(url)

      params = req.query || {}
      req.route.keys.forEach (routeKey) ->
        params[routeKey.name] = req.route.params[routeKey.name]

      start = new Date
      action.call context, params, (err, template, data) ->
        router.stashPerf(req, "data", new Date - start)
        return router.handleErr(err, req, res) if err

        start = new Date
        viewData =
          locals: data
          app: req.rendrApp
          req: req
        res.render template, viewData, (err, html) ->
          return router.handleErr(err, req, res) if err

          # Set any headers based on route.
          res.set(router.getHeadersForRoute(routeInfo))

          res.type('html').end(html)
          router.stashPerf(req, "render", new Date - start)


  ##
  # Handle an error that happens while executing an action.
  # Could happen during the controller action, view rendering, etc.
  ##
  handleErr: (err, req, res) ->
    @stashError(req, err)
    if @config.errorHandler
      @config.errorHandler(err, req, res)
    else
      # default error handler
      if @config.dumpExceptions
        text = "Error: #{err.message}\n"
        text += "\nStack:\n #{err.stack}" if err.stack
      else
        text = "500 Internal Server Error"
      res.status(err.status || 500)
      res.type('text').send(text)


  getHeadersForRoute: (routeInfo) ->
    headers = {}
    if routeInfo.maxAge?
      headers['Cache-Control'] = "public, max-age=#{routeInfo.maxAge}"
    headers

  # stash performance metrics, if handler available
  stashPerf: (req, name, value) ->
    if @config.stashPerf?
      @config.stashPerf(req, name, value)

  # stash error, if handler available
  stashError: (req, err) ->
    if @config.stashError?
      @config.stashError(req, err)

  # Build route definitions based on the routes file.
  buildRoutes: ->
    routeBuilder = require(@config.paths.routes)
    routeBuilder(@route)
    @routes()

  # Returns current route definitions.
  routes: ->
    @_routes.slice()

  # Method passed to routes file to build up routes definition.
  # Adds a single route definition.
  route: (pattern, definitions...) =>
    definition = @parseDefinitions(definitions)
    action = @getAction(definition)
    handler = @getHandler(action, definition)
    pattern = "/#{pattern}" unless pattern.slice(0, 1) is '/'
    route = [pattern, definition, handler]
    @_routes.push(route)
    route

  parseDefinitions: (definitions) ->
    definition = {}
    for element in definitions
      # Handle i.e. 'users#show'.
      if _.isString(element)
        parts = element.split('#')
        _.extend definition,
          controller: parts[0]
          action: parts[1]
      # Handle objects.
      else
        _.extend definition, element
    definition

  # We create and reuse an instance of Express Router in '@match()'.
  _expressRouter: null

  # Return the route definition based on a URL, according to the routes file.
  # This should match the way Express matches routes on the server, and our
  # ClientRouter matches routes on the client.
  match: (pathToMatch) ->
    throw new Error('Cannot match full URL: "'+pathToMatch+'". Use pathname instead.') if ~pathToMatch.indexOf('://')

    routes = @routes()
    routesByPath = {}

    # NOTE: Potential here to cache this work. Must invalidate when additional
    # routes are added.
    Router = require('express').Router
    @_expressRouter = new Router
    for route in routes
      # Add the route to the Express router, so we can use its matching logic
      # without attempting to duplicate it.
      #
      # Ensure leading slash
      path = route[0]
      @_expressRouter.route('get', path, [])
      routesByPath[path] = route

    # Ensure leading slash
    pathToMatch = "/#{pathToMatch}" unless pathToMatch.slice(0, 1) is '/'
    matchedRoute = @_expressRouter.match('get', pathToMatch)

    return null unless matchedRoute?
    routesByPath[matchedRoute.path]
