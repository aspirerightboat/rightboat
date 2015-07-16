$ ->
  $(document).ready ->
    $('.user-register').click (e) ->
      e.preventDefault()
      $('#session-popup .signin-area').hide()
      $('#session-popup .signup-area').show()
      $('#session-popup').modal()

    onSubmit = (e) ->
      e.preventDefault()
      $this = $(e.target) # form
      $this.find('button[type=submit]').attr('disabled', 'disabled')
      url = $this.attr('action')
      $.ajax
        method: 'POST'
        dataType: 'JSON'
        url: url
        data: { user: $(@).serializeObject() }
      .success ->
        # TODO: update page using ajax result instead of page refresh
        window.location = window.location
      .error ->
        console.log 'Error'
        console.log arguments
      .always =>
        $this.find('button[type=submit]').removeAttr('disabled')
    validetta_options = $.extend Rightboat.validetta_options, onValid: onSubmit
    $('.register-form').validetta(validetta_options)

    onSubmit = (e) ->
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
        $this.prepend('<div class="alert alert-success">Chnages saved successfully.</div>')
      .error ->
        console.log 'Error'
        console.log arguments
      .always =>
        $this.find('button[type=submit]').removeAttr('disabled')

    validetta_options = $.extend Rightboat.validetta_options, onValid: onSubmit
    $('.profile-form').validetta(validetta_options)
