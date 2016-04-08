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

#      set_content_height()
      false

#    set_content_height = ->
#      $('.filter-tabs-content').css(height: $('.array-filter-box').outerHeight());
#
#    set_content_height()

    collapsed = Cookies.get('filter_collapsed')
    collapsed = true if collapsed == undefined

    $('.filter-tabs-content').toggleClass('collapsed', Cookies.get('filter_collapsed'))

    $('.filter-tabs-content').find('.do-collapse, .overlay').click ->
      $cont = $(@).closest('.filter-tabs-content')
      $cont.toggleClass('collapsed')
      Cookies.set('filter_collapsed', $cont.hasClass('collapsed'))
      false