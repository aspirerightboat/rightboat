Array::shuffle = ->
  input = this
  i = input.length - 1
  while i >= 0
    randomIndex = Math.floor(Math.random() * (i + 1))
    itemAtIndex = input[randomIndex]
    input[randomIndex] = input[i]
    input[i] = itemAtIndex
    i--
  input

featuredArray = []

pickRandom = ->
  shuffled = featuredArray.shuffle()
  $('#featured-wrap .boat-thumb-container').removeClass 'active'
  i = 0
  while i < 6
    $($('#featured-wrap .boat-thumb-container')[shuffled[i]]).addClass 'active'
    i++

initialize = ->
  length = $('#featured-wrap .boat-thumb-container').length
  featuredArray = Array(length).fill().map((x,i)=>i)
  pickRandom()
  setInterval pickRandom, 30000

$ ->
  $(document).on 'ready page:load', initialize
  