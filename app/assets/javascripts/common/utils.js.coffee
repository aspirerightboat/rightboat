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
        this[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1]) if pair[0] && pair[0].length
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
      else if (json = xhr.responseJSON)
        if json.location
          setTimeout (->
            $submit.addClass('inline-loading')
            $submit.prop('disabled', true)
          ), 10
          window.location = json.location
        else if json.alert
          $form.showFormError(json.alert)
    .on 'ajax:error', (e, xhr) ->
      $('.alert', $form).remove()
      json = JSON.parse(xhr.responseText) || xhr.responseJSON
      if xhr.status == 200 # goes here when attached file
        window.location = json.location
      else
        errors = if $.isArray(json) then json else ['Something went wrong']
        $errors =  $('<div class="alert alert-danger">').prependTo($form)
        $.each errors, (i, msg) ->
          $errors.append('<div>' + msg + '</div>')
        $errors.hide().show(200)

  $.fn.showFormError = (msg) ->
    $('.alert', @).remove()
    $('<div class="alert alert-info"/>').text(msg).prependTo(@).hide().show(200)
