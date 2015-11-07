currentPage = 1
prevViewPage = 0

loadPrevPage = ->
  return if isNaN(prevViewPage)
  if currentPage < prevViewPage
    $('.view-more-link').click()

$ ->
  if $('.view-more-link').length > 0
    isLoading = false
    prevViewPage = if $('#main-content').data('prev-url') == 'boats-for-sale'
      parseInt(sessionStorage.getItem('currentPage'))
    else
      0

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
        $('.over-limit').fadeOut().remove()
        boats = response.search
        pagination = response.meta.pagination
        $.each boats, ->
          $template = $(this.template)
          $template.appendTo($('#boats-list'))
          initBoatView($template)
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