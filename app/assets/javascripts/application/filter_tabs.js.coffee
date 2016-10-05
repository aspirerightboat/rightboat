$ ->
  $('.filter-tabs').each ->
    $tabs = $(@)
    $tabs_content = $('.filter-tabs-content', $tabs)
    $toggle = $('.toggle-collapse', $tabs)
    collapse_text = $toggle.data('collapse-text') || $toggle.text()
    expand_text = $toggle.data('expand-text') || $toggle.text()

    collapse_content = (collapse) ->
      $tabs_content.toggleClass('collapsed', collapse)
      $toggle.text(if collapse then expand_text else collapse_text)

    $('.filter-tabs-nav').click (e) ->
      if e.target.tagName == 'A'
        li = e.target.parentNode
        $(@).children().each ->
          $(@).toggleClass('active', @ == li)

        target_tab = $($(e.target).attr('href')).get(0)
        $tabs_content.find('.filter-tab-content').each ->
          $(@).toggleClass('hidden', @ != target_tab)

        collapse_content(false)
        false

    collapse_content($tabs_content.hasClass('collapsed'))

    $('.overlay', $tabs_content).add($toggle).click ->
      collapse_content(!$tabs_content.hasClass('collapsed'))
      false
