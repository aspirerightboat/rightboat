$ ->
  $.fn.openLoginPopup = (title) ->
    $link = $(@)
    $('#login_popup').each ->
      $popup = $(@)

      if /my-rightboat\/saved-searches/.test($link.attr('href'))
        sessionStorage.setItem('saveSearch', '1')

      $('#login-title').text(title).show() if title
      $('#login-content').show()
      $('#register-content').hide()
      $popup.displayPopup() unless $popup.is(':visible')
    false
  
  $(document).on 'click', '.open-login-popup', (e) ->
    $link = $(e.target)
    title = $link.data('login-title')
    $link.openLoginPopup(title)
    false

  $('#login_popup').on 'hidden.bs.modal', ->
    $('form .alert', @).remove()
    $('#login-title').text('').hide()

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

  $('#trigger_welcome_popup').each ->
    $trigger = $(@)
    show_popup = ->
      $.getJSON '/welcome_popup', null, (data) ->
        $trigger.after(data.show_popup).remove()
        $('#welcome_popup').displayPopup()
    setTimeout(show_popup, 10 * 1000)
