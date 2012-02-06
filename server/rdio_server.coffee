root = exports ? this

rdio_api = require('rdio')

class root.RdioServer
  constructor: (api_key, shared_key, host) ->
    @rdio_api = rdio_api
      rdio_api_key: api_key
      rdio_api_shared: shared_key
      callback_url: "http://#{host}/oauth/callback"

  login: (callback=->) ->
    self = this
    @rdio_api.getRequestToken (error, oauth_token, oauth_token_secret, results) ->
      self.oauth_token = oauth_token
      self.oauth_token_secret = oauth_token_secret
      if error
        throw new Error error
      else
        callback "https://www.rdio.com/oauth/authorize?oauth_token=#{oauth_token}"

  oauth_callback: (oauth_verifier, callback=->) ->
    self = this
    @rdio_api.getAccessToken @oauth_token, @oauth_token_secret, oauth_verifier, (error, oauth_access_token, oauth_access_token_secret, results) ->
      self.oauth_access_token = oauth_access_token
      self.oauth_access_token_secret = oauth_access_token_secret
      callback()

  search: (query, callback=->) ->
    @rdio_api.api @oauth_access_token, @oauth_access_token_secret,
      method: 'search'
      types: "Artist, Album, Track"
      query: query
      (error, data, response) ->
        collback data
