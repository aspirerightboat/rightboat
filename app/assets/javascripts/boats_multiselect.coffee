$ ->
  if $('.multiselectable').length

    toggleBottomBar = () ->
      if $('.boat-thumb.thumbnail.selected').length > 0
        $('#multiselected-request-for-details #number-selected').text(word_with_number('boat', $('.multiselectable.selected').length) + ' selected')
        $('#multiselected-request-for-details').animate
          bottom: '0px'
      else
        $('#multiselected-request-for-details').animate
          bottom: '-55px'

    word_with_number = (word, number) ->
      if number == 1
        return(number + ' ' + word)
      else
        return(number + ' ' + word + 's')

    sendSelectedBoatsToCookies = () ->
      array = []
      $.each $('.selected .tick[data-boat-ref]'), (_, el) ->
        array.push $(el).data('boat-ref')
      Cookies.set 'boats_multi_selected', JSON.stringify({'boats_refs' : array})

    loadMultiSelected = () ->
      selectedBoats = []

      if Cookies.get 'boats_multi_selected'
        selectedBoats = JSON.parse(Cookies.get 'boats_multi_selected').boats_refs

      $.each selectedBoats, (_, ref_no) ->
        $('.tick[data-boat-ref=' + ref_no + ']').parents('.multiselectable').addClass('selected')

      if selectedBoats.length > 0
        toggleBottomBar()

    #
    # End of declaration
    #

    loadMultiSelected()

    $('.boat-thumb.thumbnail.multiselectable .tick').on 'click', (e) ->
      e.stopPropagation()
      e.preventDefault()
      $(@).parents('.boat-thumb.thumbnail.multiselectable').toggleClass('selected')
      sendSelectedBoatsToCookies()
      toggleBottomBar()

    $('.boat-thumb.thumbnail.multiselectable').on 'click', (e) ->
      if $('.multiselectable.selected').length > 0 # in selected mode
        e.preventDefault()
        $(@).toggleClass('selected')
        sendSelectedBoatsToCookies()
        toggleBottomBar()

    $('.boat-thumb .caption').click ->
      if $('.multiselectable.selected').length == 0
        window.location = $(@).data('url')

    $('#button-request-for-details').on 'click', (e) ->
      e.preventDefault()
      selectedBoats = Cookies.get 'boats_multi_selected'
      Cookies.remove 'boats_multi_selected'

      $.ajax
        type: "POST",
        url: 'boats/request-batched-details',
        data: selectedBoats,
        dataType: "json",
        contentType: 'application/json'
