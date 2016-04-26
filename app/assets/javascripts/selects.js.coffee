$ ->
  $.fn.generalSelect = ->
    @.each ->
      $sel = $(@)
      options = minimumResultsForSearch: Infinity
      if $sel.hasClass('select-white')
        options.dropdownCssClass = 'select-white'

      $sel.select2(options)

      if !$sel.initialized
        $sel.initialized = true
        $sel.on 'change', ->
          $allOption = $(@).find('option[value=""]')
          if $allOption.length and $allOption.text().match(/^all$/i)
            if $allOption.is(':selected')
              $sel.select2 'val', ''
          if $sel.data('onchange-fill-models')
            maker_id = $sel.val()
            $modelsSelect = $($sel.data('onchange-fill-models'))
            window.syncModel(maker_id, $modelsSelect)

  $('.select-general').generalSelect()


  $.fn.currencySelect = ->
    @.select2
      minimumResultsForSearch: Infinity
      dropdownAutoWidth: true
      formatSelection: (viewMode, container, escapeMarkup) ->
        viewMode.text
      formatResult: (viewMode, container, escapeMarkup) ->
        ret = '<span'
        ret += ' class="priority-last"' if viewMode.id is 'USD'
        ret += '>' + viewMode.text + ' <small>' + viewMode.id + '</small></span>'

  $('.select-currency').currencySelect()

  
  $.fn.makemodelPickers = ->
    @.each ->
      select_id = @id
      url = '/search/' + select_id.replace('s_picker', '')
      $(@).select2
        tags: true
        minimumInputLength: 0
        separator: '-'
        tokenSeparators: [',']
        initSelection: (el, callback) ->
          tags = $(el).data('initial-tags') || []
          data = $.map(tags, (arr) -> {id: arr[0], text: arr[1]})
          callback data
          return
        ajax:
          url: url
          dataType: 'JSON'
          delay: 150
          data: (term, page) ->
            h = {q: term}
            h.manufacturer_ids = $('#manufacturers_picker').val() if select_id == 'models_picker'
            h
          results: (data, page) ->
            {results: $.map(data.search, (item) -> {id: item[0], text: item[1]})}
          cache: true

  $('.manufacturers-picker, .models-picker').makemodelPickers()
  
  
  $('select#layout_mode').select2
    minimumResultsForSearch: Infinity
    formatSelection: (viewMode, container, escapeMarkup) ->
      $('<img>').attr('src', '/icons/' + viewMode.text.toLowerCase() + '-view.png').addClass 'view-mode-icon'
    formatResult: (viewMode, container, escapeMarkup) ->
      $icon = $('<img>').attr('src', '/icons/' + viewMode.text.toLowerCase() + '-view.png').addClass('view-mode-icon')
      #return $('<div>').append(viewMode.text + ' ').append($icon)
      $('<div>').append $icon
    dropdownCssClass: 'view-mode-dropdown'

  $('.multiple-country-select').each ->
    $sel = $(@)
    filtered_data = $sel.data('filtered-data')
    if !$.isEmptyObject(filtered_data)
      selected_ids = $sel.data('selected-ids') || []
      window.countries_options = $sel.html()
      $sel.empty()
      $.each filtered_data, (i, arr) ->
        id = arr[0]
        name = arr[1]
        count = arr[2]
        count = '1000+' if parseInt(count) > 1000
        opt = $('<option>').text(name+' ('+count+')').attr('value', id)
        opt.prop('selected', true) if $.inArray(''+id, selected_ids) >= 0
        $sel.append(opt)
    $sel.select2()

  $.fn.countrySelect = ->
    $(@).select2
      minimumResultsForSearch: Infinity
      dropdownAutoWidth: true
      formatSelection: (viewMode, container, escapeMarkup) ->
        viewMode.text
      formatResult: (viewMode, container, escapeMarkup) ->
        ret = '<span'
        ret += ' class="priority-last"' if /Turkey/.test viewMode.text
        ret += '>' + viewMode.text + '</span>'
  $('.country-select').countrySelect();

  $('select.country-code-select').each ->
    $(this).select2
      minimumResultsForSearch: Infinity
      dropdownAutoWidth: true
      formatSelection: (viewMode, container, escapeMarkup) ->
        splitted = viewMode.text.split(',')
        if splitted.length > 1
          $('<span>').html('<img class="flag" src="/flags/' + splitted[0] + '.png' + '"/> ' + splitted[2])
        else
          viewMode.text
      formatResult: (viewMode, container, escapeMarkup) ->
        splitted = viewMode.text.split(',')
        ret = '<span'
        if splitted.length > 1
          ret += ' class="priority-last"' if /Turkey/.test viewMode.text
          ret += '>' + splitted[1] + ' (' + splitted[2] + ')</span>'
        else
          ret += '>' + viewMode.text + '</span>'
        ret
