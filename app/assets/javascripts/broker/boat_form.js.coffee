$ ->
  $('.boat-form').each ->
    $('#manufacturer_picker, #model_picker').each ->
      $sel = $(@)
      collection = $sel.data('collection')
      url = '/search/' + collection
      $sel.selectize
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        closeAfterSelect: true,
        createOnBlur: true,
        preload: 'focus',
        maxItems: 1,
#        options: $sel.data('initial-options') || [],
        load: (query, callback) ->
          makerId = $('#manufacturer_picker').val()
          if collection == 'models' && makerId && makerId.match(/^create:/)
            callback()
          data = {q: query}
          data.manufacturer_ids = makerId if collection == 'models'
          $.getJSON url, data, (res) ->
            callback(res[collection])
          .fail ->
            callback()
        create: (input) ->
          console.log('create', input)
          name: input,
          id: 'create:' + input
        onChange: (value) ->
          makerId = $('#manufacturer_picker').val()
          modelId = $('#model_picker').val()
          if makerId && makerId.match(/^\d+$/) && modelId && modelId.match(/^\d+$/)
            console.log("load makemodel " + makerId + ' + ' + modelId)
