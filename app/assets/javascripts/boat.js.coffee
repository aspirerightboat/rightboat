window.initBoatView = (el) ->
  boat_id = $(el).data('boat-ref')

  # $('#captcha').focus ->
  #   $('.captcha-img').show()

  $('.request-details', el).click (e) ->
    url = '/boats/' + boat_id + '/request-details'
    $('.enquiry-form').attr('action', url)
    # $('.enquiry-form').find('#message, #captcha').val('')
    $('.enquiry-result-container').hide()
    $('.enquiry-form-container').show()
    $('#enquiry_popup').displayPopup()
    false

  $('.fav-link', el).click (e) ->
    window.loginTitle = 'Please sign in or join as a member to record your favourite boats.'
    return false unless requireLogin(e, false)

    $link = $(@).attr('disabled', 'disabled')
    if $link.hasClass('remove-fav')
      return false unless confirm('Are you sure you permanently want to delete this boat?')

    $.ajax
      url: '/my-rightboat/favourites'
      dataType: 'JSON'
      data: {boat_id: boat_id}
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
      $link.removeAttr('disabled')
    false

  $('.boat-img-thumb > a', el).click ->
    sessionStorage.setItem('currentScrollTop', $('body').scrollTop())

$ ->

  $('.boat-view').each ->
    initBoatView(this)

  if window.favLink
    window.favLink.click()
