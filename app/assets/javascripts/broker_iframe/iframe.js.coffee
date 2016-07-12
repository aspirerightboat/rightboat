$ ->
  $('.length-slider, .price-slider').each ->
    $(@).data('value0', '')
    $(@).data('value1', '')
    reinitSlider($(@))

  $('#iframe_search_form').each ->
    $form = $(@)
    $('button[type=submit]', $form).click ->
      params = $.param($form.serializeArray())
      url = '/search/?' + params + '&iframe=' + $form.data('iframe')
      window.open(url, '_blank').focus()
      false
