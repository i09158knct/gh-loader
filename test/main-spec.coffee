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


      it 'should be contained into url querystring', (done) ->
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
          .reply(200, """[]""")

        loader.loadReceivedEvents page, (err, res) ->
          expect(ghmock.isDone()).to.be.true
          expect(err).to.not.exist
          expect(res).to.be.an 'array'
          done()



  describe '#checkRateLimit', ->
    loader = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'


    it 'should contain User-Agent into request header', (done) ->
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
        done()



  describe '#loadReceivedEvents', ->
    loader = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'


    it 'should request received_events for specified page', (done) ->
      page = 5

      ghmock = nock('https://api.github.com')
        .matchHeader('User-Agent', /.*/)
        .get("/users/#{loader.username}/received_events?page=#{page}")
        .reply(200, """[]""")

      loader.loadReceivedEvents page, (err, res) ->
        expect(ghmock.isDone()).to.be.true
        expect(err).to.not.exist
        expect(res).to.be.an 'array'
        done()



  describe '#loadAllReceivedEvents', ->
    loader = null
    ghmocks = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'

      ghmocks = [1..10].map (i) ->
        nock('https://api.github.com')
          .matchHeader('User-Agent', /.*/)
          .get("/users/#{loader.username}/received_events?page=#{i}")
          .reply(200, JSON.stringify [1..30])


    it 'should request all received_events pages(1..10)', (done) ->
      loader.loadAllReceivedEvents (err, res) ->
        for ghmock in ghmocks
          expect(ghmock.isDone()).to.be.true
        done()


    it 'should have 300 received_events', (done) ->
      loader.loadAllReceivedEvents (err, res) ->
        expect(err).to.not.exist
        expect(res).to.have.length 300
        done()



  describe '#loadRepo', ->
    loader = null
    ghmock = null
    repoInfo =
      full_name: 'octocat/sample-repo'
      html_url: 'https://api.github.com/repos/octocat/sample-repo'

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'

      ghmock = nock('https://api.github.com')
        .matchHeader('User-Agent', /.*/)
        .get("/repos/#{repoInfo.full_name}")
        .reply(200, JSON.stringify repoInfo)


    it 'should request repo page with repo full_name', (done) ->
      loader.loadRepo repoInfo.full_name, (err, res) ->
        expect(ghmock.isDone()).to.be.true
        expect(err).to.not.exist
        expect(res).to.deep.equal repoInfo
        done()


    it 'should request repo page with repo url', (done) ->
      loader.loadRepo repoInfo.html_url, (err, res) ->
        expect(ghmock.isDone()).to.be.true
        expect(err).to.not.exist
        expect(res).to.deep.equal repoInfo
        done()


    it 'should return error with invalid repo name or url', (done) ->
      loader.loadRepo 'fjisd jfdjs', (err, res) ->
        expect(ghmock.isDone()).to.be.false
        expect(err).to.be.an.instanceof Error
        expect(res).to.not.exist
        done()


  describe '#loadStars', ->
    loader = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'


    it 'should request stars for specified page', (done) ->
      page = 5

      ghmock = nock('https://api.github.com')
        .matchHeader('User-Agent', /.*/)
        .get("/users/#{loader.username}/starred?page=#{page}&per_page=100")
        .reply(200, """[]""")

      loader.loadStars page, (err, res) ->
        expect(ghmock.isDone()).to.be.true
        expect(err).to.not.exist
        expect(res).to.be.an 'array'
        done()



  describe '#loadAllStars', ->
    loader = null
    ghmocks = null

    beforeEach ->
      loader = new GitHubLoader
        username: 'test-user'

      ghmocks = [1..15].map (i) ->
        nock('https://api.github.com')
          .matchHeader('User-Agent', /.*/)
          .get("/users/#{loader.username}/starred?page=#{i}&per_page=100")
          .reply(200, JSON.stringify [1..100])

      ghmocks = ghmocks.concat [16..20].map (i) ->
        nock('https://api.github.com')
          .matchHeader('User-Agent', /.*/)
          .get("/users/#{loader.username}/starred?page=#{i}&per_page=100")
          .reply(200, JSON.stringify [])

    it 'should request all stars', (done) ->
      loader.loadAllStars (err, res) ->
        for ghmock in ghmocks
          expect(ghmock.isDone()).to.be.true
        done()


    it 'should have 1500 stars', (done) ->
      loader.loadAllStars (err, res) ->
        expect(err).to.not.exist
        expect(res).to.have.length 1500
        done()
