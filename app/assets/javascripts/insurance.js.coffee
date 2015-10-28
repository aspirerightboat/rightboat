$(document).ready ->
  onInsuranceSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').attr('disabled', 'disabled')
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    $.ajax
      method: 'POST'
      dataType: 'JSON'
      url: url
      data: {insurance: $this.serializeObject()}
    .success (response)->
      $('<div class="alert alert-success">').remove()
      $('#insurance-popup').modal('hide')
      $('#insurance-result-popup').displayPopup()
    .error (response)->
      errors = response.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      Object.keys(errors).forEach (key) ->
        field = key.toString()
        $errors.append(field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ') + ' ' + errors[key].toString() + '<br>')
      $this.prepend($errors)
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled');

  onFinaceSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').attr('disabled', 'disabled')
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    $.ajax
      method: 'POST'
      dataType: 'JSON'
      url: url
      data: {finance: $this.serializeObject()}
    .success (response)->
      $('<div class="alert alert-success">').remove()
      $('#finance-popup').modal('hide')
      $('#finance-result-popup').displayPopup()
    .error (response)->
      errors = response.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      Object.keys(errors).forEach (key) ->
        field = key.toString()
        $errors.append(field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ') + ' ' + errors[key].toString() + '<br>')
      $this.prepend($errors)
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled');

  $('.insurance-form').rbValidetta(onValid: onInsuranceSubmit)
  $('.finance-form').rbValidetta(onValid: onFinaceSubmit)
