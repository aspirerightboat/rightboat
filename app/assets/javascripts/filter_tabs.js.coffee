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

    $('.filter-tabs').each ->
      $tabs = $(@)
      $tabs_content = $('.filter-tabs-content', $tabs)
      $toggle = $('.toggle-collapse', $tabs)

      update_toggle_text = ->
        collapsed = $tabs_content.hasClass('collapsed')
        $toggle.text(if collapsed then $toggle.data('expand-text') else $toggle.data('collapse-text'))

      update_toggle_text()

      $('.overlay', $tabs_content).add($toggle).click ->
        $tabs_content.toggleClass('collapsed')
        if !$tabs_content.hasClass('collapsed')
          $tab_content = $('.filter-tab-content:visible', $tabs_content)
          if !$tab_content.data('height')
            height = $tab_content.outerHeight()
            $tab_content.css(height: height).data('height', height) # set height for css animation
        update_toggle_text()
        false