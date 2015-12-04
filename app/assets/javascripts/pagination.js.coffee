currentPage = 1
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
    if $('#main-content').data('prev-url') == 'boats-for-sale'
      prevViewPage = parseInt(sessionStorage.getItem('currentPage'))
      sessionStorage.removeItem('currentPage')
      prevPosition = parseInt(sessionStorage.getItem('currentScrollTop'))
      sessionStorage.removeItem('currentScrollTop')

    $('.view-more-link').click (e)->
      e.preventDefault()
      $this = $(this)

      return true if isLoading
      isLoading = true

      $.ajax
        url: window.location
        method: 'GET'
        dataType: 'JSON'
        data: { page: currentPage + 1 }
      .success (response)->
        # $('.over-limit').fadeOut().remove()
        boats = response.search
        pagination = response.meta.pagination
        $.each boats, ->
          $template = $(this.template)
          $template.appendTo($('#boats-list'))
          initBoatView($template.find('.boat-view'))
        currentPage += 1
        sessionStorage.setItem('currentPage', currentPage)
        unless pagination.total_pages > currentPage
          $this.hide()
      .always ->
        isLoading = false
        loadPrevPage()

    loadPrevPage()

#    $(window).on 'scroll', ->
#      if $(window).scrollTop() > $(document).height() - $(window).height() - 200
#        $('.view-more-link').trigger('click')