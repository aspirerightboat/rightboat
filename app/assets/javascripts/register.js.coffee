$ ->
  $(document).on 'click', '.user-register', ->
    $('#login-content').hide()
    $('#register-content').show()
    $('#login_popup').displayPopup() unless $('#login_popup').is(':visible')
    false

  $('.simple-ajax-form').simpleAjaxForm()
