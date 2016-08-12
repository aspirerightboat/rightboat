window.initBoatView = (el) ->
  boat_id = $(el).data('boat-ref')

  $('.boat-thumb .caption').click (event) ->
    if $('.multiselectable.selected').length == 0
      $target = $(event.target)
      if !$target.is('i') && !$target.is('a')
        window.location = $(@).data('url')

  $('.request-details', el).click (e) ->
    url = '/boats/' + boat_id + '/request-details'
    $('.lead-form').attr('action', url).find('.alert').remove()
    $('#lead_popup').displayPopup()
    false

  $('.fav-link', el).click (e) ->
    if $('.login-button').length
      $(@).openLoginPopup('Please sign in or join as a member to record your favourite boats.')
      return false

    $link = $(@).prop('disabled', true)

    $.ajax
      url: '/my-rightboat/favourites'
      dataType: 'JSON'
      data: {boat_id: $(this).data('boat-id')}
      method: 'POST'
    .success (response) ->
      active = response.active
      title = if active then 'Unfavourite' else 'Favourite'
      $link.toggleClass('active', active).attr('title', title).tooltip('fixTitle').tooltip('show')
      if !response.active && $link.parents('#favourites').length > 0
        $link.closest('.boat-view').fadeOut()
    .error ->
      alert('Sorry, unexpected error occurred')
    .always ->
      $link.prop('disabled', false)
    false

  $('.boat-img-thumb > a', el).click ->
    sessionStorage.setItem('currentScrollTop', $('body').scrollTop())

$ ->

  $('.boat-view').each ->
    initBoatView(this)

  if window.favLink
    window.favLink.click()
