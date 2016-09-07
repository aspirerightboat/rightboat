window.initBoatView = (el) ->
  boat_id = $(el).data('boat-ref')

  $('.boat-thumb-info', el).click (event) ->
    if $('.multiselectable.selected').length == 0
      $target = $(event.target)
      if !$target.is('i') && !$target.is('a')
        window.location = $(@).closest('.boat-thumb').find('.boat-thumb-image').attr('href')

  $('.request-details', el).click (e) ->
    url = '/boats/' + boat_id + '/request-details'
    $('.lead-form').attr('action', url).find('.alert').remove()
    $('#lead_popup').displayPopup()
    false

  $('.fav-link, .remove-fav', el).click (e) ->
    if $('.login-button').length
      $(@).openLoginPopup('Please sign in or join as a member to record your favourite boats.')
      return false

    $link = $(@)

    $.ajax
      url: '/my-rightboat/favourites'
      dataType: 'JSON'
      data: {boat_id: $link.data('boat-id')}
      method: 'POST'
      beforeSend: -> $link.toggleClass('disabled-link', true)
      complete: -> $link.toggleClass('disabled-link', false)
    .success (response) ->
      if $link.hasClass('remove-fav')
        $link.closest('.boat-view').fadeOut()
      else
        $link.toggleClass('active', response.active)
        title = if response.active then 'Unfavourite' else 'Favourite'
        $link.attr('title', title).tooltip('fixTitle').tooltip('show')
    .error ->
      alert('Sorry, unexpected error occurred')
    false

  $('.boat-thumb-image', el).click ->
    sessionStorage.setItem('currentScrollTop', $('body').scrollTop())

$ ->

  $('.boat-view').each ->
    initBoatView(this)

  if window.favLink
    window.favLink.click()
