$ ->
  $('.save-search').on 'ajax:before', (e, data, status, xhr) ->
    if (form = $(@).closest('form'))
      params = $.param(form.serializeArray())
      href = '/my-rightboat/saved-searches?' + params
      $(@).find('a').first().attr('href', href)
