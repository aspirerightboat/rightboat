$ ->
  $(document).on 'click', '.user-register', ->
    $('form .alert').remove()
    $('#session-popup .signin-area').hide()
    $('#session-popup .signup-area').show()
    $('#session-popup').showPopup()
    false

  $('.register-form').each ->
    $submit = $('button[type="submit"]', @)
    $(@)
    .validetta(Rightboat.validetta_options)
    .on 'ajax:before', (e) -> $submit.addClass('inline-loading')
    .on 'ajax:complete', (e) -> $submit.removeClass('inline-loading')
    .on 'ajax:success', -> window.location = window.location
    .on 'ajax:error', (e, xhr) ->
      $('.alert', e.target).remove()
      $errors =  $('<div class="alert alert-danger">').prependTo(e.target)
      $.each xhr.responseJSON, (i, msg) ->
        $errors.append('<div>' + msg + '</div>')

  onProfileSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target) # form
    $this.find('.alert').remove()

    $this.find('button[type=submit]').attr('disabled', 'disabled')
    url = $this.attr('action')
    $.ajax
      method: 'PUT'
      dataType: 'JSON'
      url: url
      data: $this.serializeObject()
    .success ->
      $this.prepend('<div class="alert alert-success">Changes saved successfully.</div>')
    .error ->
      console.log 'Error'
      console.log arguments
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled')

  validetta_options = $.extend({onValid: onProfileSubmit}, Rightboat.validetta_options)
  $('.profile-form').validetta(validetta_options)
