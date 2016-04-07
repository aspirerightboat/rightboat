$ ->
  if $('#manufacturer_view').length
    $(document).on 'click', '.apply-filter-btn', -> apply_filter()

    apply_filter = ->
      if $('.boats-view .loading-overlay').is(':visible')
        return

      params = {}
      $('.array-filter-box').each (i, e) ->
        name = $(e).data('filter-slug')
        ids = $('.filter-checkbox:checked', e).map((ii, ee) -> $(ee).data('id')).get().join('-')
        params[name] = ids if ids
      url = location.pathname + (if params == {} then '' else '?' + $.param(params))
      xhr_load(url)
      history.pushState(null, null, url)

      false

    show_loading_overlay = (show) ->
      $('.boats-view .loading-overlay').toggle(show)

    xhr_load = (url) ->
      show_loading_overlay(true)
      $.get(url)
      .done (data) ->
        alert(data.slice(0, 20))
        $('#manufacturer_view').replaceWith(data)
        #        qwe = if data then 'state present' else 'state empty'
        #        alert('pushState, ' + qwe + ', ' + url)
        #        full_html = document.documentElement.outerHTML
      .always ->
        show_loading_overlay(false)

#    $(window).on 'popstate'
#    window.onpopstate = (e) ->
    window.addEventListener 'popstate', (e) ->
#      data = e.state
#      qwe = if data then 'state present' else 'state empty'
#      alert('popstate, ' + qwe + ', ' + location.href)
#      if data
#        document.documentElement.outerHTML = data
      xhr_load(location.href)
#      $('#manufacturer_view').replaceWith(data)

    $(document).on 'click', '.filter-tag .esc', ->
      $filter_tag = $(@).closest('.filter-tag')
      $('#' + $filter_tag.data('id')).prop('checked', false)
      $filter_tag.remove()
      apply_filter()

    $(document).on 'click', '.clear-filters-btn', ->
      $('.filter-tags .filter-tag').remove()
      $('.array-filter-box .filter-checkbox').prop('checked', false)
      apply_filter()

    $(document).on 'ajax:beforeSend', '.boats-view .remote-paginate a', ->
      show_loading_overlay(true)
