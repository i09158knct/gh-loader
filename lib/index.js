(function() {
  var GitHubLoader, Q, generateLoadingMethod, qs, request;

  request = require('request');

  qs = require('querystring');

  Q = require('q');

  generateLoadingMethod = function(clientId, clientSecret) {
    var defaults;

    defaults = {};
    if ((clientId != null) && (clientSecret != null)) {
      defaults.client_id = clientId;
      defaults.client_secret = clientSecret;
    }
    return function(target, params, cb) {
      var k, queries, uri, v;

      if (typeof params === 'function') {
        cb = params;
        params = {};
      }
      uri = 'https://api.github.com' + (target[0] === '/' ? target : '/' + target);
      queries = {};
      for (k in defaults) {
        v = defaults[k];
        queries[k] = v;
      }
      for (k in params) {
        v = params[k];
        queries[k] = v;
      }
      return request({
        uri: uri,
        qs: queries,
        method: 'GET',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7'
        }
      }, function(err, res, body) {
        if (err != null) {
          return typeof cb === "function" ? cb(err) : void 0;
        }
        if (res.statusCode !== 200) {
          return typeof cb === "function" ? cb([res.statusCode, body]) : void 0;
        }
        return typeof cb === "function" ? cb(null, JSON.parse(body)) : void 0;
      });
    };
  };

  GitHubLoader = (function() {
    function GitHubLoader(_arg) {
      var clientId, clientSecret;

      this.username = _arg.username, clientId = _arg.clientId, clientSecret = _arg.clientSecret;
      this.load = generateLoadingMethod(clientId, clientSecret);
    }

    GitHubLoader.prototype.checkRateLimit = function(cb) {
      return this.load('rate_limit', cb);
    };

    GitHubLoader.prototype.loadReceivedEvents = function(page, cb) {
      return this.load("users/" + this.username + "/received_events", {
        page: page
      }, cb);
    };

    GitHubLoader.prototype.loadPublicEvents = function(page, cb) {
      return this.load("users/" + this.username + "/events/public", {
        page: page
      }, cb);
    };

    GitHubLoader.prototype.loadAllReceivedEvents = function(cb) {
      var loadingAll,
        _this = this;

      loadingAll = Q.all([1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(function(i) {
        return Q.nfcall(_this.loadReceivedEvents.bind(_this), i);
      }));
      return loadingAll.then(function(results) {
        var _ref;

        return (_ref = []).concat.apply(_ref, results);
      }).nodeify(cb);
    };

    GitHubLoader.prototype.loadAllPublicEvents = function(cb) {
      var loadingAll,
        _this = this;

      loadingAll = Q.all([1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(function(i) {
        return Q.nfcall(_this.loadPublicEvents.bind(_this), i);
      }));
      return loadingAll.then(function(results) {
        var _ref;

        return (_ref = []).concat.apply(_ref, results);
      }).nodeify(cb);
    };

    GitHubLoader.prototype.loadRepo = function(repoKey, cb) {
      var fullname, result;

      result = repoKey.match(/https:\/\/api.github.com\/repos\/(.*)/);
      if (result != null) {
        fullname = result[1];
      } else if (repoKey.match(/\w+\/\w+/)) {
        fullname = repoKey;
      } else {
        cb(new Error('invalid repo full name or url'));
        return;
      }
      return this.load("repos/" + fullname, cb);
    };

    GitHubLoader.prototype.loadStars = function(page, cb) {
      return this.load("users/" + this.username + "/starred", {
        page: page,
        per_page: 100
      }, cb);
    };

    GitHubLoader.prototype._loadChunkStars = function(pages) {
      var loadingChunk,
        _this = this;

      loadingChunk = Q.all(pages.map(function(page) {
        return Q.nfcall(_this.loadStars.bind(_this), page);
      }));
      return loadingChunk.then(function(results) {
        var _ref;

        return (_ref = []).concat.apply(_ref, results);
      });
    };

    GitHubLoader.prototype.loadAllStars = function(cb) {
      var deferredLoadingAll, loopLoading,
        _this = this;

      deferredLoadingAll = Q.defer();
      loopLoading = function(acc, start) {
        var loading, _i, _ref, _results;

        if (acc == null) {
          acc = [];
        }
        if (start == null) {
          start = 1;
        }
        loading = _this._loadChunkStars((function() {
          _results = [];
          for (var _i = start, _ref = start + 9; start <= _ref ? _i <= _ref : _i >= _ref; start <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this));
        return loading.then(function(stars) {
          var mergedAcc;

          mergedAcc = acc.concat(stars);
          if (stars.length === 1000) {
            return loopLoading(mergedAcc, start + 10);
          } else {
            return deferredLoadingAll.resolve(mergedAcc);
          }
        }, function(reason) {
          return deferredLoadingAll.reject(reason);
        });
      };
      loopLoading();
      return deferredLoadingAll.promise.nodeify(cb);
    };

    return GitHubLoader;

  })();

  module.exports = GitHubLoader;

}).call(this);
