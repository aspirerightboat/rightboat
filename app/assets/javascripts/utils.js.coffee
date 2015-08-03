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
