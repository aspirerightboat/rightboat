$ ->
  $('.admin-maker-picker').each ->
    $makerInput = $(@)
    $modelInput = $(@).closest('form').find('.admin-model-picker')
    $makerInput.add($modelInput).each ->
      $input = $(@)
      collection = $input.data('collection')
      initVal = $input.data('current-name')+''
      url = '/search/' + collection
      $input.selectize
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        preload: 'focus',
        maxItems: 1,
        options: if $input.val() then [{id: $input.val(), name: initVal}] else [],
        load: (query, callback) ->
          maker = $makerInput.val()
          data = {q: query}
          data.manufacturer_ids = maker if collection == 'models'
          $.getJSON url, data, (res) ->
            callback(res.items)
          .fail ->
            callback()
        onChange: (value) ->
          if collection == 'manufacturers' && $modelInput.length
            sel = $modelInput.data('selectize')
            sel.clearOptions()
            return
