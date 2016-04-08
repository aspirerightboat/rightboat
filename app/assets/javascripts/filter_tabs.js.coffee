$ ->
  if $('.filter-tabs').length
    $('.filter-tabs .filter-tabs-nav a').click ->
      $filter_tabs = $(@).closest('.filter-tabs')

      $li = $(@).parent()
      $('.filter-tabs-nav > li', $filter_tabs).each ->
        $(@).toggleClass('active', @ == $li[0])

      target_tab = $($(@).attr('href'))[0]
      $('.filter-tab-content', $filter_tabs).each ->
        $(@).toggleClass('hidden', @ != target_tab)

      false

    $('.filter-tabs-content').each ->
      $tabs_content = $(@)
      $('.toggle-collapse, .overlay', $tabs_content).click ->
        $tabs_content.toggleClass('collapsed')
        if !$tabs_content.hasClass('collapsed')
          $tab_content = $('.filter-tab-content:visible', $tabs_content)
          if !$tab_content.data('height')
            height = $tab_content.outerHeight()
            $tab_content.css(height: height).data('height', height) # set height for css animation
        false
