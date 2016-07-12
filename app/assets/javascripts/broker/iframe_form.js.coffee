$ ->
  if $('.iframe-form').length
    $('#manufacturers_picker').each ->
      $input = $(@)
      initOpts = $input.data('initial-options') || []
      $input.selectize
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        preload: 'focus',
        delimiter: '-',
        maxItems: 10,
        options: initOpts,
        load: (query, callback) ->
          $.getJSON '/search/manufacturers', {q: query}, (res) ->
            callback(res.items)
          .fail ->
            callback()

    $('#countries_picker').each ->
      $input = $(@)
      $input.selectize
        maxItems: 10,
        delimiter: '-'
