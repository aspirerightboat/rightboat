$ ->
  if $('.save-search').length
    $('.save-search')
    .on 'ajax:before', (e, data, status, xhr) ->
      if (form = $(@).closest('form')).length
        params = $.param(form.serializeArray())
        href = '/my-rightboat/saved-searches?' + params
        $(@).find('a').first().attr('href', href)
    .on 'ajax:success', (e, data, status, xhr) ->
      json = xhr.responseJSON
      $(document.body).append(json.google_conversion) if json.google_conversion
      $(@).find('.saved-search-hint').fadeIn()

    $(window).click ->
      $('.saved-search-hint').fadeOut()
