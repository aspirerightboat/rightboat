class @BoatView
  constructor: (el, options)->
    @element = el
    @options = options || {}
    @boat_id = @$().data('boat-ref')

    @$('.request-details').click (e) =>
      e.preventDefault()
      return if requireLogin(e, true)
      @requestDetails()

    @$('.fav-link').click (e) =>
      e.preventDefault()
      return if requireLogin(e, true)

      $this = $(e.target)
      $this.attr('disabled', 'disabled')

      $.ajax
        url: '/my-rightboat/favourites'
        dataType: 'JSON'
        data: { boat_id: @boat_id }
        method: 'POST'
      .success (response) ->
        if response.active
          $this.addClass('active')
          $this.attr('title', 'Unfavourite')
               .tooltip('fixTitle')
               .data('bs.tooltip')
               .$tip.find('.tooltip-inner')
               .text('Unfavourite')
        else
          $this.removeClass('active')
          $this.attr('title', 'Favourite')
               .tooltip('fixTitle')
               .data('bs.tooltip')
               .$tip.find('.tooltip-inner')
               .text('Favourite')
          if $this.parents('#favourites').length > 0
            $this.parents('.boat-thumb-container').fadeOut()
      .error ->
        alert('Sorry, Unexpected error occurred.')
      .always ->
        $this.removeAttr('disabled')


  requestDetails: ->
    url = '/boats/' + @boat_id + '/request-details'
    $('.enquiry-form').attr('action', url)
    $('.enquiry-form').find('#message, #captcha').val('')
    $('.enquiry-result-container').hide()
    $('.enquiry-form-container').show()
    $('#enquiry-popup').modal('show')

  $: (selector)->
    if !selector
      $(@element)
    else
      $(@element).find(selector)

######## Enquiry form
$ ->
  $(document).ready ->
    phoneModalOpened = false

    $('[data-boat-ref]').each ->
      new BoatView(this)

    $('#enquiry-popup').modal(show: false)
    $('#enquiry-result-popup').modal(show: false)

    $('#enquiry-popup').on 'show.bs.modal', ->
      $('#enquiry-popup form').renderCaptcha()

    onSubmit = (e)->
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
      .success (response)->
        enquiry = response.enquiry
        $('#enquiry-result-popup #signup-email').hide()
        $('#enquiry-result-popup #signup-email input').val(enquiry.email)

        # hide form and show message
        $('#enquiry-popup').off('hidden.bs.modal').one 'hidden.bs.modal', ->
          $('#enquiry-result-popup').modal('show')

        $('#enquiry-popup').modal('hide')

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
        $('#enquiry-popup form').renderCaptcha()
        errors = resp.responseJSON.errors
        $errors = $('<div class="alert alert-danger">')
        $.each errors, (k, v)->
          $errors.append(k + ' ' + v + '<br>')
        $this.prepend($errors)

    validetta_options = $.extend Rightboat.validetta_options, onValid: onSubmit
    $('.enquiry-form').validetta(validetta_options)

