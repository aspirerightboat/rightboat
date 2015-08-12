$ ->
  $(document).ready ->
    setupSliderLabelPosition = ->
      $('#advanced-search .slider, #home-search .slider').each ->
        alignSliderLabelPosition($(this))

    $('.toggle-adv-search').click (e)->
      e.preventDefault()

      $('#home-search-form, #normal-navbar').slideUp
        duration: 200
        progress: setupSliderLabelPosition
        complete: ->
          $('#advanced-search').slideDown
            duration: 200
            progress: setupSliderLabelPosition
            complete: setupSliderLabelPosition

    $('#advanced-search .close').click (e) ->
      e.preventDefault()

      $('#advanced-search').slideUp
        duration: 200
        progress: setupSliderLabelPosition
        complete: ->
          $('#home-search-form, #normal-navbar').slideDown
            duration: 200
            progress: setupSliderLabelPosition
            complete: setupSliderLabelPosition

    $('#view-mode, #sort-field, select#currency, select#length_unit').change ->
      value = $(this).val().toLowerCase()
      id = $(this).attr('id')
      if id == 'currency'
        value = value.toUpperCase()
      else if id == 'view-mode'
        $('*[data-view-layout]').attr('data-view-layout', value)
      else if id == 'sort-field'
        # TODO: need to reset pagination with ajax
        params = $.queryParams()
        params.order = value
        window.location.search = $.param(params)

      param = {}
      param[id] = value
      $.ajax
        url: '/session-settings'
        method: 'PUT'
        dataType: 'JSON'
        data: param

