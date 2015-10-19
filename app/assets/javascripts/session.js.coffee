$ ->
  myRightboatClicked = false

  $('.rb-dropdown')
    .on 'mouseenter', -> $(@).addClass 'open'
    .on 'mouseleave', -> $(@).removeClass 'open'

  $('[data-require-login]').click (e) ->
    if $(this).html() is 'My Rightboat'
      myRightboatClicked = true
    requireLogin(e, false)

  $(document).on 'click', '.user-login', ->
    $('form .alert').remove()
    $('#login_popup').displayPopup()
    false

  $('#login_popup')
    .on 'hidden.bs.modal', ->
      myRightboatClicked = false
      $('.register-notice').remove()
    .on 'shown.bs.modal', ->
      if myRightboatClicked && !$('.register-notice').length > 0
        $('#login_popup .modal-body').prepend('<h5 class="text-center register-notice">To use my Rightboat, you must first Join as a Member</h5>')

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

  validetta_options = $.extend({onValid: onSubmit}, Rightboat.validetta_options)
  $('.session-form').validetta validetta_options