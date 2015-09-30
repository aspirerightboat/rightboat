$(document).ready ->
  subscriptionSubmit = null

  onContactSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').attr('disabled', 'disabled')
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    $.ajax
      method: 'POST'
      dataType: 'JSON'
      url: url
      data: $this.serializeObject()
    .success (response)->
      $notice = $('<div class="alert alert-success">')
      $notice.append('Thank you, your comments have been sent to us. If you asked for a response, you should hear back within 2 business days.')
      $this.prepend($notice)
    .error (response)->
      errors = response.responseJSON.errors
      $errors = $('<div class="alert alert-danger">')
      Object.keys(errors).forEach (key) ->
        field = key.toString()
        $errors.append(field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ') + ' ' + errors[key].toString() + '<br>')
      $this.prepend($errors)
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled');

  onSubscriptionSubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').attr('disabled', 'disabled')
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    data = $this.serializeObject()
    data.commit = subscriptionSubmit
    $.ajax
      method: 'POST'
      dataType: 'JSON'
      url: url
      data: data
    .success (response)->
      $notice = $('<div class="alert alert-success">')
      $notice.append(response.notice)
      $this.prepend($notice)
    .error (response)->
      console.log(response)
    .always =>
      $this.find('button[type=submit]').removeAttr('disabled')

  $('.mail-subsctiption-form input[type="submit"]').click (e) ->
    subscriptionSubmit = $(this).val()

  validetta_options = $.extend({onValid: onContactSubmit}, Rightboat.validetta_options)
  $('.contact-form').validetta validetta_options

  validetta_options = $.extend({onValid: onSubscriptionSubmit}, Rightboat.validetta_options)
  $('.mail-subsctiption-form').validetta validetta_options