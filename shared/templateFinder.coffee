fs = require('fs') if global.isServer
handlebars_helpers = require('./handlebars_helpers')

templates = null

for own key, func of handlebars_helpers
  Handlebars.registerHelper(key, func)

exports.getTemplate = (template) ->
  # Allow compiledTemplates to be created asynchronously.
  templates ||= require(rendr.entryPath + '/templates/compiledTemplates')

  filename = "#{template}.hbs"
  templates[filename]
