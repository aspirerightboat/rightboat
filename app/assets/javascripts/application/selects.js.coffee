$ ->
  $.fn.generalSelect = ->
    @.selectize()
    @.each ->
      $sel = $(@)
      if $sel.data('onchange-fill-models') && !$sel.initialized
        $sel.initialized = true
        $sel.on 'change', ->
          $($sel.data('onchange-fill-models')).syncModelSelect($sel.val())
  $('.select-general').generalSelect()

  $.fn.initTitleSelect = ->
    @.selectize(create: true, createOnBlur: true)
  $('.select-title').initTitleSelect()

  $.fn.currencySelect = ->
    @.selectize
      render:
        option: (item, escape) ->
          ret = '<div'
          ret += ' class="priority-last"' if item.value == 'USD'
          ret += '>' + item.text + ' <small>' + item.value + '</small></div>'
  $('.select-currency').currencySelect()

  $.fn.makemodelPickers = ->
    @.each ->
      $sel = $(@)
      collection = $sel.data('collection')
      url = '/search/' + collection
      $sel.selectize
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        closeAfterSelect: true,
        preload: 'focus',
        delimiter: '-',
        options: $sel.data('initial-options') || [],
        load: (query, callback) ->
          data = {q: query}
          data.manufacturer_ids = $sel.closest('form').find('input.manufacturers-picker').val() if collection == 'models'
          $.getJSON url, data, (res) ->
            callback(res[collection])
          .fail ->
            callback()
  $('.manufacturers-picker, .models-picker').makemodelPickers()

  $('.layout-mode-select')
  .selectize
    render:
      item: (data, escape) ->
        '<div><img class="view-mode-icon" src="/icons/' + data.text.toLowerCase() + '-view.png"></div>'
      option: (data, escape) ->
        '<div><img class="view-mode-icon" src="/icons/' + data.text.toLowerCase() + '-view.png"></div>'
  .change ->
    $('[data-layout-mode]').attr('data-layout-mode', @value)
    Cookies.set('layout_mode', @value)


  $('.multiple-country-select').each ->
    $sel = $(@)
    $sel.selectize
      render:
        item: (data, escape) ->
          '<div>' + escape(data.text.replace(/\s\(.*\)/, '')) + '</div>'
    foundCountries = $sel.data('found-countries')
    if !$.isEmptyObject(foundCountries)
      selectize = $sel.data('selectize')
      $sel.data('init-options', selectize.options)
      selectize.clear()
      selectize.clearOptions()
      $.each foundCountries, ->
        id = @[0]
        name = @[1]
        count = @[2]
        text = name + ' (' + count + ')'
        selectize.addOption(value: id, text: text)
      selectize.refreshOptions()
      selected_ids = $sel.data('selected-ids') || []
      $.each selected_ids, ->
        selectize.addItem(this, true)

  $.fn.countrySelect = ->
    @.selectize
      render:
        option: (data, escape) ->
          ret = '<div'
          ret += ' class="priority-last"' if data.value == 'Turkey'
          ret += '>' + escape(data.text) + '</div>'
  $('.country-select').countrySelect();

  $('.country-code-select').each ->
    $sel = $(@)
    $sel.selectize
      options: $sel.find('option').map(-> {value: $(@).attr('value'), iso: $(@).data('iso'), text: $(@).text()}),
      allowEmptyOption: true,
      render:
        item: (data, escape) ->
          if data.iso
            '<div><img class="flat" src="/flags/' + data.iso + '.png"> ' + data.value + '</div>'
          else
            data.text
        option: (data, escape) ->
          if data.iso
            ret = '<div'
            ret += ' class="priority-last"' if /^Turkey/.test(data.text)
            ret += '>' + escape(data.text) + '</div>'
          else
            data.text
    if !$sel.val()
      $sel.val('')
