$ ->
  $(document).on 'click', '.user-register', ->
    $('#login-content').hide()
    $('#register-content').show()
    $('#login_popup').displayPopup() unless $('#login_popup').is(':visible')
    false

  $('.simple-ajax-form').each ->
    $(this).simpleAjaxForm()

  $('.insurance-form').simpleAjaxForm ($form) ->
    $('<div class="alert alert-success">').remove()
    $('#insurance-popup').modal('hide')
    $('#insurance-result-popup').displayPopup()

  $('.finance-form').simpleAjaxForm ($form) ->
    $('<div class="alert alert-success">').remove()
    $('#finance-popup').modal('hide')
    $('#finance-result-popup').displayPopup()
