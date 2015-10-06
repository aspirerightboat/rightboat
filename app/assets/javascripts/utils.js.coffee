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
    .validetta(Rightboat.validetta_options)
    .on 'ajax:before', (e) -> $submit.addClass('inline-loading')
    .on 'ajax:complete', (e) -> $submit.removeClass('inline-loading')
    .on 'ajax:success', (e, data, status, xhr) ->
      if onComplete
        onComplete($form)
      else
        window.location = xhr.responseJSON.location
    .on 'ajax:error', (e, xhr) ->
      $('.alert', e.target).remove()
      $errors =  $('<div class="alert alert-danger">').prependTo(e.target)
      $.each xhr.responseJSON, (i, msg) ->
        $errors.append('<div>' + msg + '</div>')
