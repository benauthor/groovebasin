// Generated by IcedCoffeeScript 1.2.0l
(function() {
  var iced,
    __slice = [].slice;

  iced = {
    Deferrals: (function() {

      function _Class(_arg) {
        this.continuation = _arg;
        this.count = 1;
        this.ret = null;
      }

      _Class.prototype._fulfill = function() {
        if (!--this.count) return this.continuation(this.ret);
      };

      _Class.prototype.defer = function(defer_params) {
        var _this = this;
        ++this.count;
        return function() {
          var inner_params, _ref;
          inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (defer_params != null) {
            if ((_ref = defer_params.assign_fn) != null) {
              _ref.apply(null, inner_params);
            }
          }
          return _this._fulfill();
        };
      };

      return _Class;

    })(),
    findDeferral: function() {
      return null;
    }
  };

  $(document).ready(function() {
    var $console, socket;
    window.WEB_SOCKET_SWF_LOCATION = "/public/vendor/socket.io/WebSocketMain.swf";
    socket = io.connect(void 0, {
      'force new connection': true
    });
    $console = $('#console');
    $console.empty();
    $console.log = function(string) {
      $console.append("" + string + "\n");
      return $("html,body").animate({
        scrollTop: $(document).height()
      }, 'fast');
    };
    socket.on('rdioframeactivate', function(playback_token) {
      $console.log("playback token: " + playback_token);
      return $('#rdio').rdio(playback_token);
    });
    socket.on('rdioframeplay', function(key) {
      $console.log("rdioframeplay: " + key);
      return $('#rdio').rdio().play(key);
    });
    socket.emit('rdioframeinitialize', window.location.toString());
    $('#rdio').bind('ready.rdio', function() {
      return $console.log('rdio is ready');
    });
    $('#rdio').bind('playStateChanged.rdio', function(event, play_state) {
      return $console.log("play_state: " + play_state);
    });
    $('#rdio').bind('playingTrackChanged.rdio', function(event, playing_track, source_position) {
      if (playing_track) return $console.log("duration " + playing_track.duration);
    });
    return $('#rdio').bind('positionChanged.rdio', function(event, position) {
      return $console.log("position: " + position);
    });
  });

}).call(this);
