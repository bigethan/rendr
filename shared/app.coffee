# This is the app instance that is shared between client and server.
# The client also subclasses it for client-specific stuff.

require('./globals');

fetcher = require('./fetcher')
ClientRouter = require(rendr.entryPath + "/router");

module.exports = class App extends Backbone.Model
  defaults:
    loading: false

  # @shared
  initialize: ->
    @fetcher = fetcher
    @fetcher.app = @

    if !global.isServer
      @router = new ClientRouter(app: @)

  # To be overridden.
  loggedIn: ->
    false

  # @client
  bootstrapData: (modelMap) ->
    results = {}
    for own name, map of modelMap
      modelOrCollection = @fetcher.getModelForSpec(map.summary, map.data, _.pick(map.summary, 'params', 'meta'))
      results[name] = modelOrCollection
    @fetcher.storeResults results

  # @client
  start: ->
    @router.start()
