$ ->
  $('.register-broker-link').click ->
    $link = $(this)
    if !$link.hasClass('.inline-loading')
      $link.addClass('.inline-loading')
      $.getScript($(this).attr('href'))
      .always -> $link.removeClass('.inline-loading')
    false

$.fn.initRegisterBrokerPopup = ->
  $('.select-title', @).initTitleSelect()
  $submit = $('button[type="submit"]', @)
  @
  .validetta(Rightboat.validetta_options)
  .on 'ajax:before', (e) -> $submit.addClass('inline-loading')
  .on 'ajax:complete', (e) -> $submit.removeClass('inline-loading')
  .on 'ajax:success', (e, data, status, xhr) -> window.location = xhr.responseJSON.location
  .on 'ajax:error', (e, xhr) ->
    if xhr.status == 422
      $('.alert', e.target).remove()
      $errors =  $('<div class="alert alert-danger">').prependTo(e.target)
      $.each xhr.responseJSON, (i, msg) ->
        $errors.append('<div>' + msg + '</div>')

$ ->
  $('.display-office-popup').click ->
    $('#add_office_popup').displayPopup()