$(document).ready ->
  onBerthEnquirySubmit = (e) ->
    e.preventDefault()
    $this = $(e.target)
    $this.find('button[type=submit]').attr('disabled', 'disabled')
    $this.find('.alert').remove()
    url = $(e.target).attr('action')
    $.ajax
      method: 'POST'
      dataType: 'JSON'
      url: url
      data: {berth_enquiry: $this.serializeObject()}
    .success (response)->
      $notice = $('<div class="alert alert-success">')
      $notice.append('Thank you, your request have been sent to us.')
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

  $('.berth-enquiry-form').submit(onBerthEnquirySubmit);
