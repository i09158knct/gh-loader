request = require 'request'
qs      = require 'querystring'
Q       = require 'q'


generateLoadingMethod = (clientId, clientSecret) ->
  defaults = {}
  if clientId? && clientSecret?
    defaults.client_id = clientId
    defaults.client_secret = clientSecret

  return (target, params, cb) ->
    if typeof params == 'function'
      cb = params
      params = {}

    uri = 'https://api.github.com' +
      if target[0] == '/'
        target
      else
        '/' + target

    queries = {}
    (queries[k] = v for k, v of defaults)
    (queries[k] = v for k, v of params)
    request
      uri: uri
      qs: queries
      method: 'GET'
      headers:
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7'
    , (err, res, body) ->
      return cb? err if err?
      return cb? [res.statusCode, body] if res.statusCode != 200
      return cb? null, JSON.parse body



class GitHubLoader
  constructor: ({@username, clientId, clientSecret}) ->
    @load = generateLoadingMethod clientId, clientSecret

  checkRateLimit: (cb) ->
    @load 'rate_limit', cb

  loadReceivedEvents: (page, cb) ->
    @load "users/#{@username}/received_events",
      page: page
    , cb

  loadPublicEvents: (page, cb) ->
    @load "users/#{@username}/events/public",
      page: page
    , cb

  loadAllReceivedEvents: (cb) ->
    loadingAll = Q.all [1..10].map (i) =>
      Q.nfcall @loadReceivedEvents.bind(@), i

    loadingAll.then((results) -> [].concat results...)
    .nodeify(cb)


  loadAllPublicEvents: (cb) ->
    loadingAll = Q.all [1..10].map (i) =>
      Q.nfcall @loadPublicEvents.bind(@), i

    loadingAll.then((results) -> [].concat results...)
    .nodeify(cb)


  loadRepo: (repoKey, cb) ->
    result = repoKey.match(/https:\/\/api.github.com\/repos\/(.*)/)
    if result?
      fullname = result[1]
    else if repoKey.match /\w+\/\w+/
      fullname = repoKey
    else
      cb new Error('invalid repo full name or url')
      return

    @load "repos/#{fullname}", cb


  loadStars: (page, cb) ->
    @load "users/#{@username}/starred",
      page: page
      per_page: 100
    , cb

  _loadChunkStars: (pages) ->
    loadingChunk = Q.all pages.map (page) =>
      Q.nfcall @loadStars.bind(@), page

    return loadingChunk.then((results) -> [].concat results...)


  loadAllStars: (cb) ->
    deferredLoadingAll = Q.defer()

    loopLoading = (acc=[], start=1) =>
      loading = @_loadChunkStars [start..(start + 9)]
      loading.then(
        (stars) ->
          mergedAcc = acc.concat stars
          if stars.length == 1000
            loopLoading mergedAcc, (start + 10)
          else
            deferredLoadingAll.resolve mergedAcc
      ,
        (reason) ->
          deferredLoadingAll.reject reason
      )

    loopLoading()
    deferredLoadingAll.promise.nodeify(cb)


module.exports = GitHubLoader
