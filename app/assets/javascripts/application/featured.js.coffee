Array::shuffle = ->
  i = @length - 1
  while i > 0
    r = Math.floor(Math.random() * (i + 1))
    t = @[r]
    @[r] = @[i]
    @[i] = t
    i--
  @

pickRandom = ->
  tiles = $('.featured-boats .boat-thumb-container')
  indexes = tiles.map((i, e) -> i).toArray().shuffle()
  for i in [0...indexes.length]
    $(tiles[i]).toggleClass('active', i < 6)

$(document).on 'ready page:load', ->
  pickRandom()
  setInterval pickRandom, 30000
