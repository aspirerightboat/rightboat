$ ->
  $(document).on 'click', '.user-register', ->
    $('#login-content').hide()
    $('#register-content').show()
    $('#login_popup').displayPopup() unless $('#login_popup').is(':visible')
    false

  $('.simple-ajax-form').each ->
    $(@).simpleAjaxForm()

  $('.reset-password-form').simpleAjaxForm ($form) ->
    $('.alert', $form).remove()
    $('#reset-password-result-popup').displayPopup()

  $('.mail-subscription-form').simpleAjaxForm ($forme, data, status, xhr) ->
    $('.alert', $form).remove()
    $('<div class="alert alert-info">' + xhr.responseText.notice + '</div>').prependTo($form).hide().show(200)
