$ ->
  window.loginTitle = null

  $('.require-login').click (e) ->
    window.loginTitle = $(this).data('login-title')
    requireLogin(e, false)

  $(document).on 'click', '.user-login', ->
    $('#login-content').show()
    $('#register-content').hide()
    $('#login_popup').displayPopup() unless $('#login_popup').is(':visible')
    false

  $('#login_popup')
    .on 'hidden.bs.modal', ->
      $('form .alert').remove()
      window.loginTitle = null
      $('#login-title').html('').hide()
    .on 'shown.bs.modal', ->
      if window.loginTitle && window.loginTitle.length > 0
        $('#login-title').html(window.loginTitle).show()

  onSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').prop('disabled', true)
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    $.post(url, $this.serializeObject(), null, 'json')
    .done (data) ->
      return_to = data.return_to
      if return_to
        window.location = return_to
      else
        window.location.reload()
    .fail (xhr) ->
      $errors = $('<div class="alert alert-danger"/>')
      if (json = xhr.responseJSON)
        errors = json.errors
        $.each errors, ->
          $errors.append(this + '<br>')
      else
        $errors.text('Something went wrong')
      $errors.prependTo($this)
    .always ->
      $this.find('button[type=submit]').prop('disabled', false)

  $('.session-form').rbValidetta(onValid: onSubmit)
