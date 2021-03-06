$ ->
  $(document).on 'click', '.open-register-popup', ->
    $('#login-content').hide()
    $('#register-content').show()
    $('#login_popup').displayPopup() unless $('#login_popup').is(':visible')
    false

  $('.reset-password-form').simpleAjaxForm ($form) ->
    $('.alert', $form).remove()
    $('#reset-password-result-popup').displayPopup()

  $('.mail-subscription-form').simpleAjaxForm ($forme, data, status, xhr) ->
    $('.alert', $form).remove()
    $('<div class="alert alert-info">' + xhr.responseText.notice + '</div>').prependTo($form).hide().show(200)

  $('#signup_form').on 'ajax:success', (e, data) ->
      $(document.body).append(data.google_conversion) if data.google_conversion
