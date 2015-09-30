initBoatView = (el) ->
  boat_id = $(el).data('boat-ref')

  $('.request-details', el).click (e) ->
    return false if requireLogin(e, true)
    url = '/boats/' + boat_id + '/request-details'
    $('.enquiry-form').attr('action', url)
    $('.enquiry-form').find('#message, #captcha').val('')
    $('.enquiry-result-container').hide()
    $('.enquiry-form-container').show()
    $('#enquiry-popup').showPopup()
    false

  $('.fav-link', el).click (e) ->
    return false if requireLogin(e, true)

    $link = $(@).attr('disabled', 'disabled')

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

######## Enquiry form
$ ->
  phoneModalOpened = false

  $('.boat-view').each ->
    initBoatView(this)

  $('#enquiry-popup').on 'show.bs.modal', ->
    $('form', @).renderCaptcha()

  onSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target) # form
    phoneNumber = $this.find('#phone').val()

    if phoneNumber == '' && !phoneModalOpened
      $('#phone-popup').modal('show')
      phoneModalOpened = true
      return false

    $this.find('.alert').remove()
    url = $this.attr('action')
    $.ajax
      url: url
      method: 'POST'
      dataType: 'JSON'
      data: { enquiry: $this.serializeObject() }
    .success (enquiry) ->
      $('#enquiry-result-popup #signup-email').hide()
      $('#enquiry-result-popup #signup-email input').val(enquiry.email)

      $('#enquiry-result-popup').showPopup()

      # signup form
      if enquiry.user_registered
        $('#enquiry-result-popup .signup-form-container').hide()
      else
        $('#enquiry-result-popup .signup-form-container').show()

      # broker info
      $('#enquiry-result-popup #broker-name').html(enquiry.broker.name)
      if enquiry.broker.phone && enquiry.broker.phone.length > 0
        $('#enquiry-result-popup #broker-phone').html(', ' + enquiry.broker.phone)

      # pdf link
      $('#enquiry-result-popup #boat-pdf').attr('href', enquiry.boat_pdf)

      # similar boats
      if enquiry.similar_boats.length > 0
        $similar_boats = $('<div>')
        $.each enquiry.similar_boats, ->
          boatThumb = $('<div class="col-xs-4 col-sm-3 col-lg-2">')
          boatLink = $('<a>').attr('href', '/boats/' + @slug)
          boatLink.append($('<img>').attr('src', @primary_image.mini))
          boatThumb.append(boatLink)
          $similar_boats.append(boatThumb)
        $('#enquiry-result-popup .similar-boats').html($similar_boats.html()).show()
        $('#enquiry-result-popup .similar-boats-link').show()
      else
        $('#enquiry-result-popup .similar-boats-link').hide()
        $('#enquiry-result-popup .similar-boats').hide()
    .error (resp)->
      $this.renderCaptcha()
      errors = resp.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      $.each errors, (k, v)->
        $errors.append(k + ' ' + v + '<br>')
      $this.prepend($errors)

  validetta_options = $.extend({onValid: onSubmit}, Rightboat.validetta_options)
  $('.enquiry-form').validetta(validetta_options)

