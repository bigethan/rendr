MemoryStore = require('./memory_store')
LocalStorageStore = require('./local_storage_store')
modelUtils = require('../model_utils')

# TODO: be less magical. Use composition instead of inheritance.
BaseClass = if LocalStorageStore.canHaz()
  LocalStorageStore
else
  MemoryStore

module.exports = class CollectionStore extends BaseClass

  set: (collection, params = null) ->
    params ||= collection.params
    key = getStoreKey(collection.constructor.name, params)
    data =
      ids: collection.pluck('id')
      meta: collection.meta
    super key, data, null

  # Returns an array of model ids.
  get: (collectionName, params = {}) ->
    key = getStoreKey(collectionName, params)
    super key

  _formatKey: (key) ->
   "_cs:#{key}"

getStoreKey = (collectionName, params) ->
  "#{collectionName.toLowerCase()}:#{JSON.stringify(params)}"
