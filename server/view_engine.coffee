path = require('path')
fs = require('fs')
_ = require('underscore')


exports.engine = (viewPath, data, callback) ->
  data.locals ||= {}

  layoutData = _.extend {}, data,
    body: getViewHtml(viewPath, data.locals, data.app)
    appData: data.app.toJSON()
    bootstrappedData: getBootstrappedData(data.locals)
    _app: data.app

  renderWithLayout(layoutData, callback)


# render with a layout
renderWithLayout = (locals, cb) ->
  layoutPath = "#{rendr.entryPath}/templates/layout.hbs"

  getLayoutTemplate (err, templateFn) ->
    return cb(err) if err
    start = new Date
    html = templateFn(locals)
    console.log(">>>>>>renderWithLayout.render", new Date - start)
    cb(null, html)


layoutTemplate = null
# Cache layout template function.
getLayoutTemplate = (callback) ->
  return callback(null, layoutTemplate) if layoutTemplate
  layoutPath = "#{rendr.entryPath}/templates/layout.hbs"
  fs.readFile layoutPath, 'utf8', (err, str) ->
    return callback (err) if (err)
    layoutTemplate = Handlebars.compile(str)
    callback(null, layoutTemplate)

getViewHtml = (viewPath, locals, app) ->
  BaseView = require('../shared/base/view')

  locals = _.clone locals
  # Pass in the app.
  locals.app = app

  name = path.basename(viewPath).replace('.coffee', '')
  View = BaseView.getView(name)
  view = new View(locals)
  view.getHtml()


getBootstrappedData = (locals) ->
  fetcher = require('../shared/fetcher')
  modelUtils = require('../shared/model_utils')

  bootstrappedData = {}
  for own name, modelOrCollection of locals
    if modelUtils.isModel(modelOrCollection) or modelUtils.isCollection(modelOrCollection)
      bootstrappedData[name] =
        summary: fetcher.summarize(modelOrCollection)
        data: modelOrCollection.toJSON()

  bootstrappedData
