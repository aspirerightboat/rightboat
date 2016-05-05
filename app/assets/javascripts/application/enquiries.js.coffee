$ ->
# $('#enquiry_popup').on 'show.bs.modal', ->
#   $('form', @).renderCaptcha()

  $('.enquiry-form').each ->
    $form = $(@).simpleAjaxForm()
    $form
    .on 'ajax:before', (e) ->
      $('#has_account').val $('.enquiry-form #password').is(':visible')
      ###
      $phone = $('#enquiry_phone')
      if $phone.is(':visible') && !$phone.val() && !$('#phone_popup').is(':visible')
        $('#phone_popup').modal('show')
        false
      ###
    .on 'ajax:success', (e, data, status, xhr) ->
      json = xhr.responseJSON
      $(document.body).append(json.google_conversion) if json.google_conversion
      if json.show_result_popup
        $('#enquiry_result_popup').displayPopup()

    $('#enquiry_result_popup').on 'hidden.bs.modal', ->
      window.location = location.href if $form.data('just-logged-in')

    $('.open-features-popup').click ->
      loggedIn = !$('.user-login').length || $form.data('just-logged-in')
      if (!loggedIn)
        $('#features_popup').modal('show')
        false

    $('.enquiry-without-phone').click ->
      $('.enquiry-form').submit()

    $('#enquiry_signup_form')
    .on 'ajax:before', (e) ->
      $('#signup_email').val($('#enquiry_email').val())
      $('#signup_title').val($('#enquiry_title').val())
      $('#signup_first_name').val($('#enquiry_first_name').val())
      $('#signup_last_name').val($('#enquiry_last_name').val())
      $('#signup_phone').val($('#enquiry_country_code').val() + ' ' + $('#enquiry_phone').val())
      $('#signup_boat').val($form.data('boat-slug'))
    .on 'ajax:success', (e, data, status, xhr) ->
      json = xhr.responseJSON
      $(document.body).append(json.google_conversion) if json.google_conversion

  $('.hide-enquiry').on 'ajax:success', (e, data, status, xhr) ->
    $(@).closest('.boat-thumb-container').fadeOut()

  $('.unhide-enquires').on 'ajax:success', (e, data, status, xhr) ->
    $('.boat-thumb-container').fadeIn()

  $('#follow_lead_maker_model_popup').each ->
    $popup = $(@).displayPopup()
    $popup.on 'ajax:success', (e, data, status, xhr) ->
      $popup.modal('hide')
