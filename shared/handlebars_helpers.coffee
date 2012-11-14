BaseView = null
templateFinder = require('./template_finder')
cdn = require('../server/lib/cdn') if global.isServer

# Temporary, to fix bug in Handlebars
# SEE https://github.com/wycats/handlebars.js/issues/342
Handlebars.log ||= (obj) -> console.log obj

Polyglot.registerHandlebars(Handlebars)

module.exports =
  asset_url: (path) ->
    cdn.assetUrl(path)

  view: (viewName, block) ->
    BaseView ||= require('./base/view')

    options = block.hash || {}

    app = @_app
    options.app = app if app?

    # get the Backbone.View based on viewName
    ViewClass = BaseView.getView(viewName)
    view = new ViewClass(options)

    # create the outerHTML using className, tagName
    html = view.getHtml()
    new Handlebars.SafeString(html)

  partial: (templateName, block) ->
    template = templateFinder.getTemplate(templateName)

    options = block.hash || {}
    data = options.context || this

    html = template(data)
    new Handlebars.SafeString(html)

  json: (object) ->
    new Handlebars.SafeString JSON.stringify(object) || 'null'
