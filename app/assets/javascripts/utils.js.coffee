$ ->
  $.fn.serializeObject = ->
    o = {}
    a = @serializeArray()
    $.each a, ->
      if o[@name] != undefined
        if !o[@name].push
          o[@name] = [o[@name]]
        o[@name].push(@value || '')
      else
        o[@name] = @value || ''
    o

  $.extend
    queryParams: (query)->
      query ||= document.location.search
      query.replace(/(^\?)/, '').split('&').map(((token)->
        pair = token.split('=')
        this[pair[0]] = decodeURIComponent(pair[1]) if pair[0] && pair[0].length
        this
      ).bind({}))[0]
    numberWithCommas: (x) ->
      x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");

  $.fn.simpleAjaxForm = (onComplete = null) ->
    $form = @
    $submit = $('button[type="submit"]', $form)
    $form
    .rbValidetta()
    .on 'ajax:beforeSend', (e) ->
      $submit.addClass('inline-loading')
      $submit.prop('disabled', true)
    .on 'ajax:complete', (e) ->
      $submit.removeClass('inline-loading')
      $submit.prop('disabled', false)
    .on 'ajax:success', (e, data, status, xhr) ->
      $('.alert', $form).remove()
      if onComplete
        onComplete($form, e, data, status, xhr)
      else if xhr.responseJSON && (loc = xhr.responseJSON.location)
        window.location = loc
      else if message = $form.data('message')
        $('<div class="alert alert-info">' + message + '</div>').prependTo($form).hide().show(200)
    .on 'ajax:error', (e, xhr) ->
      $('.alert', $form).remove()
      if xhr.status == '200' # goes here when attached file
        window.location = xhr.responseJSON.location
      else
        json = xhr.responseJSON
        errors = if $.isArray(json) then json else ['Something went wrong']
        $errors =  $('<div class="alert alert-danger">').prependTo($form)
        $.each errors, (i, msg) ->
          $errors.append('<div>' + msg + '</div>')
        $errors.hide().show(200)
