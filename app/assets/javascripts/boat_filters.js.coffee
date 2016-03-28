$ ->
  $('.filter-models-box').each ->
    $box = $(@)

    $('.filter-btn', $box).click ->
      $('#boats_view .loading-overlay').show()
      $checked_inputs = $box.find('.filter-model:checked')
      models_ids_str = $.makeArray($checked_inputs.map((i, e) -> $(e).data('model'))).join(',')
      url = window.location.pathname + '/filter?model_ids=' + models_ids_str
      $.getScript(url)
    false
