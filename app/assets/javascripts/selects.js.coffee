$ ->

  $('select.select-general').each ->
    $this = $(this)
    options = minimumResultsForSearch: Infinity
    if $this.hasClass('select-white')
      options = $.extend(options, dropdownCssClass: 'select-white')
    $this.select2(options).on 'change', (e) ->
      $allOption = $(this).find('option[value=""]')
      if $allOption.length and $allOption.text().match(/^all$/i)
        if $allOption.is(':selected')
          $this.select2 'val', ''
      if $this.attr('id') == 'manufacturer_id'
        window.syncModel(e.added.id, $this.parents('form').find('#model_id'))

  $('select.select-currency').each ->
    $(this).select2
      minimumResultsForSearch: Infinity
      dropdownAutoWidth: true
      formatSelection: (viewMode, container, escapeMarkup) ->
        viewMode.text
      formatResult: (viewMode, container, escapeMarkup) ->
        ret = '<span'
        ret += ' class="priority-last"' if viewMode.id is 'USD'
        ret += '>' + viewMode.text + ' <small>' + viewMode.id + '</small></span>'

  $('#manufacturer_model').select2
    tags: true
    minimumInputLength: 0
    tokenSeparators: [ ',' ]
    initSelection: (el, callback) ->
      tags = $(el).val().split(',')
      data = $.map(tags, (token) ->
        { id: token, text: token }
      )
      callback data
      return
    ajax:
      url: '/manufacturer-model'
      dataType: 'JSON'
      delay: 150
      data: (term, page) ->
        { q: term, page: page }
      results: (data, page) ->
        { results: $.map(data.search, (item) ->
            { id: item, text: item }
          )
        }
      cache: true

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
        opt = $('<option>').text(name+' ('+count+')').attr('value', id)
        opt.prop('selected', true) if $.inArray(''+id, selected_ids) >= 0
        $sel.append(opt)
    $sel.select2()

  $('select.country-select').each ->
    $(this).select2
      minimumResultsForSearch: Infinity
      dropdownAutoWidth: true
      formatSelection: (viewMode, container, escapeMarkup) ->
        viewMode.text
      formatResult: (viewMode, container, escapeMarkup) ->
        ret = '<span'
        ret += ' class="priority-last"' if /Turkey/.test viewMode.text
        ret += '>' + viewMode.text + '</span>'

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