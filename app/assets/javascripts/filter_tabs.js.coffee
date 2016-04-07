$ ->
  if $('.filter-tabs').length
    $(document).on 'click', '.filter-tabs .filter-tabs-nav a', ->
      $filter_tabs = $(@).closest('.filter-tabs')

      $li = $(@).parent()
      $('.filter-tabs-nav > li', $filter_tabs).each ->
        $(@).toggleClass('active', @ == $li[0])

      target_tab = $($(@).attr('href'))[0]
      $('.filter-tabs-content > div', $filter_tabs).each ->
        $(@).toggleClass('hidden', @ != target_tab)

      false