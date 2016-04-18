$ ->
  if $('#manufacturer_view').length
    $('.apply-filter-btn').click -> apply_filter()

    apply_filter = ->
      if $('.boats-view .loading-overlay').is(':visible')
        return

      params = {}
      $('.array-filter-box').each (i, e) ->
        name = $(e).data('filter-slug')
        ids = $('.filter-checkbox:checked', e).map((ii, ee) -> $(ee).data('id')).get().join('-')
        params[name] = ids if ids
      url = location.pathname
      url += '?' + $.param(params) if !$.isEmptyObject(params)
      load_page(url)

      false

    show_loading_overlay = (show) ->
      $('.boats-view .loading-overlay').toggle(show)

    load_page = (url) ->
      show_loading_overlay(true)
      location.href = url

    $('.filter-tag .esc').click ->
      $filter_tag = $(@).closest('.filter-tag')
      $('#' + $filter_tag.data('id')).prop('checked', false)
      $filter_tag.remove()
      apply_filter()

    $('.clear-filters-btn').click ->
      $('.filter-tags .filter-tag').remove()
      $('.array-filter-box .filter-checkbox').prop('checked', false)
      apply_filter()

    $('.array-filter-box .group-h').click ->
      $checkboxes = $(@).closest('.grouped').find('input[type=checkbox]')
      check = !$checkboxes.first().prop('checked')
      $checkboxes.prop('checked', check)
