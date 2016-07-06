$ ->
  $('.clear-filters').click ->
    $form = $(@).closest('form')
    $('input[name]', $form).val('')
    $('select', $form).each ->
      if $(@).data('selectize') then $(@).data('selectize').clear() else $(@).val('')
    $form.submit()
