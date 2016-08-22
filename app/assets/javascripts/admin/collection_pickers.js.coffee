$ ->
  $('.admin-collection-picker').each ->
    $input = $(@)
    collection = $input.data('collection')
    url = '/search/' + collection
    selectize = $input.selectize
      valueField: 'id',
      labelField: 'name',
      searchField: 'name',
      openOnFocus: true,
      preload: 'focus',
      maxItems: 1,
      options: if $input.val() then [{id: $input.val(), name: $input.data('init-item-text')+''}] else [],
      load: (query, callback) ->
        params = {q: query}
        if ($includeParam = $($input.data('include-param'))).length
          params[$includeParam.attr('id')] = $includeParam.val()
        $.getJSON url, params, (res) ->
          callback(res.items)
        .fail ->
          callback()

    if ($onchangeClear = $($input.data('onchange-clear'))).length
      $input.change ->
        $onchangeClear.data('selectize').clearOptions()
