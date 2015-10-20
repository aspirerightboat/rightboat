$ ->

  $('select.select-general').each ->
    options = minimumResultsForSearch: Infinity
    if $(this).hasClass('select-white')
      options = $.extend(options, dropdownCssClass: 'select-white')
    $(this).select2(options).on 'change', ->
      $allOption = $(this).find('option[value=\'\']')
      if $allOption.length and $allOption.text().match(/^all$/i)
        if $allOption.is(':selected')
          $(this).select2 'val', ''

  $('select.select-currency').each ->
    $(this).select2
      minimumResultsForSearch: Infinity
      formatSelection: (viewMode, container, escapeMarkup) ->
        viewMode.text
      formatResult: (viewMode, container, escapeMarkup) ->
        viewMode.text + '(' + viewMode.id + ')'

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

  $('#keywords').select2
    tags: true
    minimumInputLength: 1
    tokenSeparators: [ ',' ]
    initSelection: (el, callback) ->
      tags = $(el).val().split(',')
      data = $.map(tags, (token) ->
        { id: token, text: token }
      )
      callback data
      return
    ajax:
      url: '/suggestion'
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

  $('select#view-mode').select2
    minimumResultsForSearch: Infinity
    formatSelection: (viewMode, container, escapeMarkup) ->
      $('<img>').attr('src', '/icons/' + viewMode.text.toLowerCase() + '-view.png').addClass 'view-mode-icon'
    formatResult: (viewMode, container, escapeMarkup) ->
      $icon = $('<img>').attr('src', '/icons/' + viewMode.text.toLowerCase() + '-view.png').addClass('view-mode-icon')
      #return $('<div>').append(viewMode.text + ' ').append($icon)
      $('<div>').append $icon
    dropdownCssClass: 'view-mode-dropdown'

  $('.country-select').multipleSelect
    placeholder: 'Select Countries...'
    selectAllText: 'Check/Uncheck All'
    selectAllDelimiter: [ '', '' ]
