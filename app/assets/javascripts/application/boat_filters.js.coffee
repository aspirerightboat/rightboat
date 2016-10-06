$ ->
  if $('#manufacturer_view').length
    $('.apply-filter-btn').click -> apply_filter()

    apply_filter = ->
      if $('.boats-view .loading-overlay').is(':visible')
        return false

      params = $('#other_filters_form').serializeObject()
      for k, v of params
        delete params[k] if !v || k == 'utf8' || k == 'authenticity_token'
      delete params.currency if !params.price_min && !params.price_max
      delete params.length_unit if !params.length_min && !params.length_max

      $('.array-filter-box').each ->
        name = $(@).data('filter-slug')
        ids = $('.filter-checkbox:checked', @).map((i, el) -> $(el).data('id')).get().join('-')
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

    clear_other_filter = (id) ->
      switch id
        when 'boat_type' then $('#filters_boat_type_all').prop('checked', true)
        when 'year', 'price', 'length'
          $slider = $('#other_filters .'+id+'-slider')
          $slider.data('value0', '')
          $slider.data('value1', '')
          reinitSlider($slider)
        when 'q', 'ref_no' then $('#other_filters_form')[0][id].value = ''
        when 'new_used' then $('#filters_new_used_new, #filters_new_used_used').prop('checked', false)
        when 'tax_status' then $('#filters_tax_status_paid, #filters_tax_status_unpaid').prop('checked', false)

    $('.filter-tag .esc').click ->
      $filter_tag = $(@).closest('.filter-tag')
      $('#' + $filter_tag.data('id')).prop('checked', false)
      clear_other_filter($filter_tag.data('id'))
      $filter_tag.remove()
      apply_filter()

    $('.clear-filters-btn').click ->
      $('.filter-tags .filter-tag').remove()
      $('.array-filter-box .filter-checkbox').prop('checked', false)
      for id in ['boat_type', 'year', 'price', 'length', 'q', 'ref_no', 'new_used', 'tax_status']
        clear_other_filter(id)
      apply_filter()

    $('.array-filter-box .group-h').click ->
      $checkboxes = $(@).closest('.grouped').find('input[type=checkbox]')
      check = !$checkboxes.first().prop('checked')
      $checkboxes.prop('checked', check)

    $('.array-filter-box[data-filter-slug=countries]').each ->
      $filterBox = $(@)
      $usCheckbox = $('#country_' + $(@).data('us-country-id'))
      $notUsCheckboxes = $('.filter-checkbox', @).not($usCheckbox)
      $statesFilters = $('#states_filters')
      $filterBox.on 'change', '.filter-checkbox', ->
        usCheckedOnly = $usCheckbox.is(':checked') && !$notUsCheckboxes.is(':checked')
        if usCheckedOnly then $statesFilters.slideDown() else $statesFilters.slideUp()
        $('.filter-checkbox', $statesFilters).prop('checked', false) unless usCheckedOnly
