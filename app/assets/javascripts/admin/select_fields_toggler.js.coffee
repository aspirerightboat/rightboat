$ ->
  $('[data-select-fields-toggler]').each ->
    $(@).change ->
      val = $(@).val()
      scope = $(@).data('select-fields-toggler')
      $('option', @).each ->
        optionValue = $(@).attr('value')
        klass = scope + '-' + optionValue
        $('.' + klass).prop('disabled', val != optionValue)
    .change()
