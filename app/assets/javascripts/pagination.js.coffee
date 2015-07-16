$ ->
  $(document).ready ->
    window.currentPage = 1
    if $('.view-more-link').length > 0
      isLoading = false
      $('.view-more-link').click (e)->
        e.preventDefault()

        return true if isLoading
        isLoading = true

        $.ajax
          url: window.location
          method: 'GET'
          dataType: 'JSON'
          data: { page: currentPage + 1 }
        .success (response)->
          boats = response.search
          pagination = response.meta.pagination
          $.each boats, ->
            $template = $(this.template)
            $template.appendTo($('#boats-list'))
            new BoatView($template)
          window.currentPage += 1
          unless pagination.total_pages > currentPage
            $('.view-more-link').hide()
            return
        .always ->
          isLoading = false

#      $(window).on 'scroll', ->
#        if $(window).scrollTop() > $(document).height() - $(window).height() - 200
#          $('.view-more-link').trigger('click')