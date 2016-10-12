currentPage = 1
nextPage = 2
prevViewPage = 1
prevPosition = 0

loadPrevPage = ->
  return if isNaN(prevViewPage)

  if currentPage < prevViewPage
    $('.view-more-link').click()
  else
    if !isNaN(prevPosition) && prevPosition > 0
      $('html, body').animate
        scrollTop: prevPosition
      , 1000
      prevViewPage = 1
      prevPosition = 0

$ ->
  if $('.view-more-link').length > 0
    isLoading = false
    if $('#main_content').data('prev-url') == 'boats-for-sale'
      prevViewPage = parseInt(sessionStorage.getItem('currentPage'))
      sessionStorage.removeItem('currentPage')
      prevPosition = parseInt(sessionStorage.getItem('currentScrollTop'))
      sessionStorage.removeItem('currentScrollTop')

    $('.view-more-link').click ->
      $moreLink = $(@)
      return true if isLoading
      isLoading = true

      $.getJSON window.location, {page: nextPage}, (data) ->
        $(data.items_html).appendTo($('#boats-list')).find('.boat-view').each ->
          initBoatView(@)
        currentPage = data.current_page
        nextPage = data.next_page
        sessionStorage.setItem('currentPage', currentPage)
        unless nextPage
          $moreLink.remove()
      .always ->
        isLoading = false
        loadPrevPage()

      false
    loadPrevPage()

#    $(window).on 'scroll', ->
#      if $(window).scrollTop() > $(document).height() - $(window).height() - 200
#        $('.view-more-link').trigger('click')
