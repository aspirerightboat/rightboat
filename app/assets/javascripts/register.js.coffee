$ ->
  $(document).ready ->
    $('.user-register').click (e) ->
      $('form .alert').remove()
      $('#session-popup .signin-area').hide()
      $('#session-popup .signup-area').show()
      $('#session-popup').modal()
      false

    onRegisterSubmit = (e) ->
      e.preventDefault()
      $this = $(e.target) # form
      $this.find('button[type=submit]').attr('disabled', 'disabled')
      url = $this.attr('action')
      $.ajax
        method: 'POST'
        dataType: 'JSON'
        url: url
        data: { user: $this.serializeObject() }
      .success ->
        # TODO: update page using ajax result instead of page refresh
        window.location = window.location
      .error (response) ->
        errors = response.responseJSON.errors
        $errors = $('<div class="alert alert-danger">')
        Object.keys(errors).forEach (key) ->
          field = key.toString()
          $errors.append(field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ') + ' ' + errors[key].toString() + '<br>')
        $this.prepend($errors)
      .always =>
        $this.find('button[type=submit]').removeAttr('disabled')
    validetta_options = $.extend Rightboat.validetta_options, onValid: onRegisterSubmit
    $('.register-form').validetta(validetta_options)

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

    validetta_options = $.extend Rightboat.validetta_options, onValid: onProfileSubmit
    $('.profile-form').validetta(validetta_options)
