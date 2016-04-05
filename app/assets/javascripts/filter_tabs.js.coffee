$ ->
  $('.filter-tabs').each ->
    $filter_tabs = $(@)

    $('.filter-tabs-nav a', $filter_tabs).click ->
      $li = $(@).parent()
      $('.filter-tabs-nav > li', $filter_tabs).each ->
        $(@).toggleClass('active', @ == $li[0])

      target_tab = $($(@).attr('href'))[0]

      $('.filter-tabs-content > div', $filter_tabs).each ->
        $(@).toggleClass('hidden', @ != target_tab)
      false