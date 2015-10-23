$ ->
  $(document).on 'click', '.user-register', ->
    $('#register-content').slideDown()
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
      errors = response.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      Object.keys(errors).forEach (key) ->
        field = key.toString()
        $errors.append(field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ') + ' ' + errors[key].toString() + '<br>')
      $this.prepend($errors)
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled')

  validetta_options = $.extend({onValid: onProfileSubmit}, Rightboat.validetta_options)
  $('.profile-form').validetta(validetta_options)
