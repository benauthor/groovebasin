# convenience
schedule = (delay, func) -> window.setInterval(func, delay)

context =
  playing: -> this.status?.state == 'play'

mpd  = null
rdio = null
base_title = document.title
userIsSeeking = false
userIsVolumeSliding = false
MARGIN = 10

renderPlaylist = ->
  context.playlist = mpd.playlist.item_list
  $playlist = $("#playlist")
  $playlist.html Handlebars.templates.playlist(context)

  if (cur_id = mpd.status?.current_item?.id)?
    $("#playlist-track-#{cur_id}").addClass('current')

  handleResize()

renderLibraryTree = (artists, empty_message) ->
  context.artists = artists
  context.empty_library_message = if mpd.haveFileListCache then empty_message else "loading..."
  $("#library").html Handlebars.templates.library(context)
  handleResize()
renderLibrary = -> renderLibraryTree mpd.library.artists, "Empty Library"
renderSearch = -> renderLibraryTree mpd.search_results.artists, "No Results Found"

updateSliderPos = ->
  return if userIsSeeking
  return if not mpd.status?.time? or not mpd.status.current_item?
  if mpd.status.track_start_date? and mpd.status.state == "play"
    diff_sec = (new Date() - mpd.status.track_start_date) / 1000
  else
    diff_sec = mpd.status.elapsed
  $("#track-slider").slider("option", "value", diff_sec / mpd.status.time)
  $("#nowplaying .elapsed").html formatTime(diff_sec)
  $("#nowplaying .left").html formatTime(mpd.status.time)

renderNowPlaying = ->
  # set window title
  track = mpd.status.current_item?.track
  if track?
    track_display = "#{track.name} - #{track.artist_name} - #{track.album.name}"
    document.title = "#{track_display} - #{base_title}"
  else
    track_display = ""
    document.title = base_title

  # set song title
  $("#track-display").html(track_display)

  if mpd.status.state?
    # set correct pause/play icon
    toggle_icon =
      play: ['ui-icon-play', 'ui-icon-pause']
      stop: ['ui-icon-pause', 'ui-icon-play']
    toggle_icon.pause = toggle_icon.stop
    [old_class, new_class] = toggle_icon[mpd.status.state]
    $("#nowplaying .toggle span").removeClass(old_class).addClass(new_class)

    # hide seeker bar if stopped
    $("#track-slider").toggle mpd.status.state isnt "stop"

  updateSliderPos()

  # update volume pos
  if mpd.status?.volume? and not userIsVolumeSliding
    $("#vol-slider").slider 'option', 'value', mpd.status.volume

  handleResize()

render = ->
  renderPlaylist()
  renderLibrary()
  renderNowPlaying()

formatTime = (seconds) ->
  seconds = Math.floor seconds
  minutes = Math.floor seconds / 60
  seconds -= minutes * 60
  hours = Math.floor minutes / 60
  minutes -= hours * 60
  zfill = (n) ->
    if n < 10 then "0" + n else "" + n
  if hours != 0
    return "#{hours}:#{zfill minutes}:#{zfill seconds}"
  else
    return "#{minutes}:#{zfill seconds}"

setUpUi = ->
  $pl_window = $("#playlist-window")
  $pl_window.on 'click', 'a.clear', ->
    mpd.clear()
    return false
  $pl_window.on 'click', 'a.randommix', ->
    mpd.queueRandomTracks 1
    return false
  $pl_window.on 'click', 'a.repopulate', ->
    mpd.queueRandomTracks 20
    return false

  $playlist = $("#playlist")
  $playlist.on 'click', 'a.track', (event) ->
    track_id = $(event.target).data('id')
    mpd.playId track_id
    return false
  $playlist.on 'click', 'a.remove', (event) ->
    $target = $(event.target)
    track_id = $target.data('id')
    mpd.removeId track_id
    return false

  $library = $("#library")
  $library.on 'click', 'div.track', (event) ->
    mpd.queueFileNext $(this).data('file')

  $library.on 'click', 'div.expandable', (event) ->
    $div = $(this)
    $ul = $div.parent().find("> ul")
    $ul.toggle()

    old_class = 'ui-icon-triangle-1-se'
    new_class = 'ui-icon-triangle-1-e'
    [new_class, old_class] = [old_class, new_class] if $ul.is(":visible")
    $div.find("div").removeClass(old_class).addClass(new_class)
    return false
  $library.on 'mouseover', 'div.hoverable', (event) ->
    $(this).addClass "ui-state-active"
  $library.on 'mouseout', 'div.hoverable', (event) ->
    $(this).removeClass "ui-state-active"

  $library.on 'click', 'li.track', (event) ->
    file = $(event.target).data('file')
    mpd.queueFile file
    return false

  $("#lib-filter").on 'keydown', (event) ->
    if event.keyCode == 27
      $(event.target).val("")
      mpd.search ""
      return false

  $("#search-form").submit (event) ->
    mpd.search $(event.target).val()
    rdio.search $(this).find('input').val()
    return false

  actions =
    'toggle': ->
      if mpd.status.state == 'play'
        mpd.pause()
      else
        mpd.play()
    'prev': -> mpd.prev()
    'next': -> mpd.next()
    'stop': -> mpd.stop()
  $nowplaying = $("#nowplaying")
  for cls, action of actions
    do (cls, action) ->
      $nowplaying.on 'mousedown', "li.#{cls}", (event) ->
        action()
        return false

  $("#track-slider").slider
    step: 0.0001
    min: 0
    max: 1
    change: (event, ui) ->
      return if not event.originalEvent?
      mpd.seek ui.value * mpd.status.time
    slide: (event, ui) ->
      $("#nowplaying .elapsed").html formatTime(ui.value * mpd.status.time)
    start: (event, ui) -> userIsSeeking = true
    stop: (event, ui) -> userIsSeeking = false
  setVol = (event, ui) ->
    return if not event.originalEvent?
    mpd.setVolume ui.value
  $("#vol-slider").slider
    step: 0.01
    min: 0
    max: 1
    change: setVol
    start: (event, ui) -> userIsVolumeSliding = true
    stop: (event, ui) -> userIsVolumeSliding = false

  # move the slider along the path
  schedule 100, updateSliderPos

  $lib_tabs = $("#lib-tabs")
  $lib_tabs.on 'mouseover', 'li', (event) ->
    $(this).addClass 'ui-state-hover'
  $lib_tabs.on 'mouseout', 'li', (event) ->
    $(this).removeClass 'ui-state-hover'


initHandlebars = ->
  Handlebars.registerHelper 'time', formatTime

handleResize = ->
  $nowplaying = $("#nowplaying")
  $lib = $("#library-window")
  $pl_window = $("#playlist-window")

  # go really small to make the window as small as possible
  $nowplaying.width MARGIN
  $pl_window.height MARGIN
  $lib.height MARGIN
  $pl_window.css 'position', 'absolute'
  $lib.css 'position', 'absolute'

  # then fit back up to the window
  $nowplaying.width $(document).width() - MARGIN * 2
  second_layer_top = $nowplaying.offset().top + $nowplaying.height() + MARGIN
  $lib.offset
    left: MARGIN
    top: second_layer_top
  $pl_window.offset
    left: $lib.offset().left + $lib.width() + MARGIN
    top: second_layer_top
  $pl_window.width $(window).width() - $pl_window.offset().left - MARGIN
  $lib.height $(window).height() - $lib.offset().top - MARGIN
  $pl_window.height $lib.height()

  # make the inside containers fit
  $lib_header = $lib.find(".window-header")
  $("#library-items").height $lib.height() - $lib_header.position().top - $lib_header.height() - MARGIN
  $pl_header = $pl_window.find(".window-header")
  $("#playlist-items").height $pl_window.height() - $pl_header.position().top - $pl_header.height() - MARGIN

$(document).ready ->
  setUpUi()
  initHandlebars()


  mpd = new window.Mpd()
  rdio = new window.RdioClient()


  window.WEB_SOCKET_SWF_LOCATION = "/public/vendor/socket.io/WebSocketMain.swf"
  socket = io.connect(undefined, {'force new connection': true})
  socket.on 'frommpd', mpd.handleData
  socket.on 'connect', ->
    mpd.updateArtistList()
    mpd.updateStatus()
    mpd.updatePlaylist()

  mpd.onError (msg) -> alert msg
  mpd.onLibraryUpdate renderLibrary
  mpd.onSearchResults renderSearch
  mpd.onPlaylistUpdate renderPlaylist
  mpd.onStatusUpdate ->
    renderNowPlaying()
    renderPlaylist()
  mpd.onSendData (msg) ->
    socket.emit 'tompd', msg

  rdio.onSearch (query) ->
    socket.emit 'rdiosearch', query

  render()
  handleResize()

$(window).resize handleResize

window._debug_context = context
