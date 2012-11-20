BaseModel = require('./base/model')
BaseCollection = require('./base/collection')

exports.getModel = (path, attrs = {}, options = {}) ->
  path = underscorize(path)
  model = classMap[path] || require(rendr.entryPath + "/models/#{path}")
  new model(attrs, options)

exports.getCollection = (path, models = [], options = {}) ->
  path = underscorize(path)
  collection = classMap[path] || require(rendr.entryPath + "/collections/#{path}")
  new collection(models, options)

exports.isModel = (obj) ->
  obj instanceof BaseModel

exports.isCollection = (obj) ->
  obj instanceof BaseCollection


classMap = {}
# Use this to specify class constructors based on
# model/collection name. Useful i.e. for testing.
exports.addClassMapping = (key, modelConstructor) ->
 classMap[underscorize(key)] = modelConstructor


uppercaseRe = /([A-Z])/g
exports.underscorize = underscorize = (name) ->
  name = name.replace(uppercaseRe, (char) -> "_" + char.toLowerCase())
  name = name.slice(1) if name[0] is '_'
  name

exports.modelName = (modelOrCollection) ->
  underscorize(modelOrCollection.constructor.name)
