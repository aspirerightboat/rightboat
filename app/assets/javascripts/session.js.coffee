$(document).ready ->
  $('.rb-dropdown')
    .on 'mouseenter', ->
      $(this).addClass 'open'
    .on 'mouseleave', ->
      $(this).removeClass 'open'

  $('[data-require-login]').click (e) ->
    requireLogin(e)
    true

  $('.user-login').click (e) ->
    e.preventDefault()
    $('form .alert').remove()
    $('#session-popup .signin-area').show()
    $('#session-popup .signup-area').hide()
    if $(this).hasClass 'broker-login'
      $('.login-form-title').html('Broker Area')
    else
      $('.login-form-title').html('Sign In')
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
      if return_to
        location = return_to
      else
        window.location.reload()
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