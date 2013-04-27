chai = require 'chai'
nock = require 'nock'
expect = chai.expect
assert = chai.assert
GitHubLoader = require '../'


describe 'GitHubLoader', ->



  describe 'constructor', ->

    describe 'username', ->
      it 'should be required when construct', ->
        create = ->
          new GitHubLoader
            username: 'test-user'
        createWithNone = ->
          new GitHubLoader()

        expect(create).to.not.throw Error
        expect(createWithNone).to.throw Error


    describe 'client tokens', ->
      loader = null
      clientId = 'xxIdxx'
      clientSecret = 'xxSecretxx'

      beforeEach ->
        loader = new GitHubLoader
          username: 'test-user'
          clientId: clientId
          clientSecret: clientSecret


      it 'should be contained into url querystring', ->
        page = 1

        # FIXME: this querystring matching is order sensitive
        ghmock = nock('https://api.github.com')
          .matchHeader('User-Agent', /.*/)
          .get(
            "/users/#{loader.username}/received_events" +
            "?client_id=#{clientId}" +
            "&client_secret=#{clientSecret}" +
            "&page=#{page}"
          )
          .reply(200, """{}""")

        loader.loadReceivedEvents page, (err, res) ->
          expect(ghmock.isDone()).to.be.true
          expect(err).to.not.exist
          expect(res).to.be.an 'object'



  describe '#checkRateLimit', ->
    loader = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'


    it 'should contain User-Agent into request header', ->
      ghmock = nock('https://api.github.com')
        .matchHeader('User-Agent', /.*/)
        .get('/rate_limit').reply(200, """
          {
            "rate": {
              "limit": 60,
              "remaining": 60
            }
          }
        """)

      loader.checkRateLimit (err, res) ->
        expect(ghmock.isDone()).to.be.true
        expect(err).to.not.exist
        expect(res).to.be.an 'object'



  describe '#loadReceivedEvents', ->
    loader = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'


    it 'should request received_events for specified page', ->
      page = 5

      ghmock = nock('https://api.github.com')
        .matchHeader('User-Agent', /.*/)
        .get("/users/#{loader.username}/received_events?page=#{page}")
        .reply(200, """{}""")

      loader.loadReceivedEvents page, (err, res) ->
        expect(ghmock.isDone()).to.be.true
        expect(err).to.not.exist
        expect(res).to.be.an 'object'


  describe '#loadAllReceivedEvents', ->
    loader = null
    ghmocks = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'

      ghmocks = for i in [1..10]
        nock('https://api.github.com')
          .matchHeader('User-Agent', /.*/)
          .get("/users/#{loader.username}/received_events?page=#{i}")
          .reply(200, JSON.stringify [1..30])


    it 'should request all received_events pages(1..10)', ->
      loader.loadAllReceivedEvents (err, res) ->
        for ghmock in ghmocks
          expect(ghmock.isDone()).to.be.true


    it 'should have 300 received_events', ->
      loader.loadAllReceivedEvents (err, res) ->
        expect(err).to.not.exist
        expect(res).to.have.length 300
