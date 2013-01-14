require('../../shared/globals')
should = require('should')
router = require('../../server/router')

describe "server/router", ->

  describe "match", ->

    beforeEach (done) ->
      config =
        paths:
          entryPath: 'bogus'
          routes: "#{__dirname}/../fixtures/routes"
      router.init(config, done)

    it "should return the route info for a matched path", ->
      routeInfo = router.match('users/1234')
      routeInfo.should.eql
        controller: 'users'
        action: 'show'

    it "should return null if no match", ->
      should.not.exist(router.match('abcd1234xyz'))

    it "should match in the right order", ->
      routeInfo = router.match('users/thisisaparam')
      routeInfo.should.eql
        controller: 'users'
        action: 'show'

      routeInfo = router.match('users/login')
      routeInfo.should.eql
        controller: 'users'
        action: 'login'
