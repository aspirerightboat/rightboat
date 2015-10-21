$ ->
  $(document).on 'click', '.user-register', ->
    $('#login-content').hide()
    $('#register-content').show()
    $('#login_popup').modal('show') unless $('#login_popup').is(':visible')
    false

  $('.simple-ajax-form').simpleAjaxForm()

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
