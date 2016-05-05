player = undefined

window.onYouTubeIframeAPIReady = ->
  player = new (YT.Player)('player',
    videoId: 'l4e-R1g1K1c'
    events:
      'onStateChange': onPlayerStateChange)

onPlayerStateChange = (event) ->
  state = event.data
  if state == YT.PlayerState.BUFFERING or state == YT.PlayerState.PLAYING
    if $('.playing #player').length == 0
      playVideo()
  else if state == YT.PlayerState.ENDED or state = YT.PlayerState.PAUSED
    $('.video-wrapper').removeClass 'playing'

playVideo = ->
  $('.video-wrapper').addClass 'playing'

stopVideo = ->
  player.stopVideo()

$ ->

  $('.video-poster').click ->
    $(this).closest('.video-wrapper').addClass 'playing'
    player.playVideo()