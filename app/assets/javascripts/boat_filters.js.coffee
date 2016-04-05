$ ->
  $('.search-boat-filters').each ->
    $('.array-filter-box .filter-btn', @).click -> apply_filter()

  if $('#filter_tags').length
    $(document).on 'click', '.filter-tag .esc', (e) ->
      $filter_tag = $(@).closest('.filter-tag')
      $('#' + $filter_tag.data('id')).prop('checked', false)
      $filter_tag.remove()
      apply_filter()

  apply_filter = ->
    $('#boats_view .loading-overlay').show()
    params = {}
    $('.array-filter-box').each (i, e) ->
      name = $(e).data('filter-slug')
      ids = $('.filter-checkbox:checked', e).map((ii, ee) -> $(ee).data('id')).get().join(',')
      params[name] = ids if ids
    url = window.location.pathname + '/filter?' + $.param(params)
    $.getScript(url)
    false
