$ ->
  $.fn.syncModelSelect = (maker_id) ->
    $modelSelect = @
    selectize = $modelSelect.data('selectize')
    value = $modelSelect.val()

    if selectize
      selectize.disable()
    else
      $modelSelect.prop('disabled', true)

    if maker_id && /^\d+$/.test(maker_id)
      url = '/api/manufacturers/' + maker_id + '/models'
      data = {manufacturer: maker_id}
      $.getJSON url, data, (res) ->
        if selectize
          selectize.clearOptions()
          options = $.map res, (arr) -> {value: arr[0], text: arr[1]}
          selectize.addOption(options)
        else
          $modelSelect.empty()
          $('<option>').attr('value', '').text('Any').appendTo($modelSelect)
          $.each res, ->
            $opt = $('<option>').attr('value', @[0]).text(@[1]).appendTo($modelSelect)
            $opt.prop('selected', true) if @[0] == value
      .always ->
        if selectize
          selectize.enable()
        else
          $modelSelect.prop('disabled', false)
