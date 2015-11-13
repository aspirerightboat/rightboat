$ ->
  # $('#enquiry_popup').on 'show.bs.modal', ->
  #   $('form', @).renderCaptcha()

  phoneModalOpened = false

  onSubmit = (e) ->
    e.preventDefault()

    # prevent spams to submit form
    if $('#honeypot').val().length != 0
      return false

    $this = $(e.target) # form
    $phone = $this.find('#phone')

    if $phone.is(':visible')
      phoneNumber = $phone.val()
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
      $('#enquiry_result_popup').each ->
        $(@).displayPopup()

        $('.signup-form-container', @).toggle(!enquiry.user_registered)
        if !enquiry.user_registered
          $enq_form = $('.enquiry-form')
          $('.signup-email', @).val($('.enq-req-email', $enq_form).val())
          $('select.signup-title', @)[0].selectize.setValue($('.enq-req-title', $enq_form).val())
          $('.signup-first-name', @).val($('.enq-req-fname', $enq_form).val())
          $('.signup-last-name', @).val($('.enq-req-lname', $enq_form).val())

        $('#broker_name').html(enquiry.broker.name)
        $('#broker_phone').html(enquiry.broker.phone).before(', ') if enquiry.broker.phone

        $('#pdf_link').attr('href', enquiry.boat_pdf)

        any_similar = enquiry.similar_boats.length > 0
        if enquiry.similar_link
          $('.similar-boats-link a', @).attr('href', enquiry.similar_link)
        $('.similar-boats-link', @).toggle(any_similar)
        $similar_boats = $('.similar-boats', @).empty().toggle(any_similar)
        $.each enquiry.similar_boats, ->
          $similar_boats.append(
            $('<div class="col-xs-4 col-sm-3 col-lg-2">').append(
              $('<a>').attr('href', '/boats-for-sale/' + @slug).append(
                $('<img>').attr('src', @primary_image.mini))))
    .error (resp)->
      errors = resp.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      $.each errors, (k, v)->
        $errors.append(k + ' ' + v + '<br>')
      $this.prepend($errors)

  $('.enquiry-form').rbValidetta(onValid: onSubmit)

  $('.hide-enquiry ').on 'ajax:success', (e, data, status, xhr) ->
    $(this).parents('.boat-thumb-container').fadeOut()

  $('.unhide-enquires').on 'ajax:success', (e, data, status, xhr) ->
    $('.boat-thumb-container').fadeIn()

  $('.enquiry-without-phone').click ->
    $('.enquiry-form').submit()

