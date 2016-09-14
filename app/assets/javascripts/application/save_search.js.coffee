$ ->
  if $('.save-search-link').length
    $('.save-search-link')
    .on 'ajax:before', ->
      if (form = $(@).closest('form')).length
        params = $.param(form.serializeArray())
        url = $(@).attr('href').replace(/\?.*/, '')
        $(@).attr('href', url + '?' + params)
    .on 'ajax:success', (e, data, status, xhr) ->
      $(document.body).append(data.google_conversion) if data.google_conversion
      $('.saved-search-hint').fadeIn()
      $(window).on 'click.ss-hint', ->
        $('.saved-search-hint').fadeOut()
        $(@).off('click.ss-hint')
