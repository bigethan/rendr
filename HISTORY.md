# 0.2.0
## 2013-04-05
* Breaking change: Passing real `req` as first argument to `dataAdapter.makeRequest`.
* Fixing bug in ClientRouter when no querystring.
* Also return `@collection.meta` and `@collection.params` in `BaseView::getTemplateData()`.
* Support passing three args to `App::fetch()`.

# 0.1.1
## 2013-04-01
* ClientRouter params include querystring params, just like ServerRouter.

# 0.1.0
## 2013-04-01
* Initial release.
