$(document).ready ->
  $('[data-require-login]').click (e) ->
    requireLogin(e)
    true

  $('.user-login').click (e) ->
    e.preventDefault()
    $('#session-popup .signin-area').show()
    $('#session-popup .signup-area').hide()
    $('#session-popup').modal()

  onSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').attr('disabled', 'disabled')
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    $.ajax
      method: 'POST'
      dataType: 'JSON'
      url: url
      data: { user: $this.serializeObject() }
    .success (response)->
      # TODO: update page using ajax result instead of page refresh
      return_to = response.return_to
      window.location = (return_to || window.location)
    .error (response)->
      errors = response.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      $.each errors, ->
        $errors.append(this + '<br>')
      $this.prepend($errors)
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled')

  validetta_options = $.extend Rightboat.validetta_options, onValid: onSubmit
  $('.session-form').validetta validetta_options