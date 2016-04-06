$ ->
  $('.search-boat-filters').each ->
    $('.array-filter-box .filter-btn', @).click -> apply_filter()

  if $('#filter_tags').length
    $(document).on 'click', '.filter-tag .esc', ->
      $filter_tag = $(@).closest('.filter-tag')
      $('#' + $filter_tag.data('id')).prop('checked', false)
      $filter_tag.remove()
      apply_filter()

    $(document).on 'click', '.clear-filters-btn', ->
      $('#filter_tags .filter-tag').remove()
      $('.array-filter-box .filter-checkbox').prop('checked', false)
      apply_filter()

  apply_filter = ->
    $('.boats-view .loading-overlay').show()
    params = {}
    $('.array-filter-box').each (i, e) ->
      name = $(e).data('filter-slug')
      ids = $('.filter-checkbox:checked', e).map((ii, ee) -> $(ee).data('id')).get().join(',')
      params[name] = ids if ids
    url = window.location.pathname + '/filter?' + $.param(params)
    $.getScript(url)
    false

  if $('.boats-view').length
    $(document).on 'ajax:beforeSend', '.boats-view .remote-paginate a', ->
      $('.boats-view .loading-overlay').show()

  window.update_filters_counts = (all_counts) ->
    $.each all_counts, (entities, counts) ->
      console.log(entities, counts)
      $('.array-filter-box[data-filter-slug=' + entities + '] .filter-checkbox').each ->
        console.log($(@).data('id'), counts[$(@).data('id')])
        new_count = counts[$(@).data('id')] || 0
        $(@).closest('.checkbox-container').find('.filter-item small').text('(+' + new_count + ')')
