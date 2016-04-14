$ ->
  $('.save-search').on 'ajax:before', (e, data, status, xhr) ->
    if (form = $(@).closest('form')).length
      params = $.param(form.serializeArray())
      href = '/my-rightboat/saved-searches?' + params
      $(@).find('a').first().attr('href', href)

  $('.toggle-saved-searches-alerts input[type=checkbox]').on 'click', (e, data, status, xhr) ->
    $('.toggle-saved-searches-alerts .toggle-alert').trigger('click')
