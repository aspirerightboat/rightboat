$ ->
  $('.toggle-adv-search').click (e) ->
    $('#search-hub-form, #top-navbar').slideUp
      duration: 200
      complete: ->
        $('.advanced-search').slideDown
          duration: 200
    $('html, body').animate({scrollTop: 0}, 400)
    false

  $('.advanced-search .close').click (e) ->
    $('.advanced-search').slideUp
      duration: 200
      complete: ->
        $('#search-hub-form, #top-navbar').slideDown
          duration: 200
    false
