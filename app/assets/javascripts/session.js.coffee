adjustLoginLink = ->
  if $(window).width() > 767
    $('.rb-dropdown')
      .on 'mouseenter', -> $(@).addClass 'open'
      .on 'mouseleave', -> $(@).removeClass 'open'
  else
    $('.rb-dropdown')
      .unbind('mouseenter')
      .unbind('mouseleave')

$ ->
  window.loginTitle = null

  $('.require-login').click (e) ->
    window.loginTitle = $(this).data('login-title')
    requireLogin(e, false)

  $(document)
  .on('ready', adjustLoginLink)
  .on 'click', '.user-login', ->
    $('#login-content').show()
    $('#register-content').hide()
    $('#login_popup').displayPopup() unless $('#login_popup').is(':visible')
    false

  $(window).resize ->
    adjustLoginLink()

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
        window.location = return_to
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

  $('.session-form').rbValidetta(onValid: onSubmit)
