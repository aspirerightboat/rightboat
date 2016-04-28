$ ->
  if $('.multiselectable').length
    file_url = ''
    jobID = ''
    jobStatus = ''

    toggleBottomBar = () ->
      if $('.boat-thumb.thumbnail.selected').length > 0
        if jobStatus.length == 0
          $('#multiselected-request-for-details .processing').text('').hide()
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
      $.each $('.selected .tick[data-boat-id]'), (_, el) ->
        array.push $(el).data('boat-id')
      Cookies.set 'boats_multi_selected', JSON.stringify({'boats_ids' : array})

    loadMultiSelected = () ->
      selectedBoats = []

      if Cookies.get 'boats_multi_selected'
        selectedBoats = JSON.parse(Cookies.get 'boats_multi_selected').boats_ids

      $.each selectedBoats, (_, id) ->
        $('.tick[data-boat-id=' + id + ']').parents('.multiselectable').addClass('selected')

      if selectedBoats.length > 0
        toggleBottomBar()

    getStatus = () ->
      $.ajax
        type: "get",
        url: 'batch_upload_jobs/' + jobID,
      .done (response) ->
        $('#multiselected-request-for-details .processing').text(response.status).show()
        jobStatus = response.status
        if jobStatus != 'processing'
          $('#multiselected-request-for-details .processing').text(response.status).removeClass('inline-loading')
          jobStatus = ''

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
      return if $(e.target).hasClass('view-summary') # obey view summary button in anyt case
      if $('.multiselectable.selected').length > 0 # in selected mode
        e.preventDefault()
        $(@).toggleClass('selected')
        sendSelectedBoatsToCookies()
        toggleBottomBar()

    $('.boat-thumb .caption').click ->
      if $('.multiselectable.selected').length == 0
        window.location = $(@).data('url')

    $('#button-request-for-details-clear').click ->
      $('.multiselectable').removeClass('selected')
      toggleBottomBar()
      Cookies.remove 'boats_multi_selected'
      false

    $('#button-request-for-details').on 'click', (e) ->
      $('#enquiry_popup').displayPopup()

    $('#send_button').on 'click', (e) ->
      e.preventDefault()
      selectedBoats = Cookies.get 'boats_multi_selected'
      selectedBoatsData = JSON.parse(selectedBoats || null)
      formData = $('.enquiry-form').serializeObject()
      Cookies.remove 'boats_multi_selected'
      $.ajax
        type: "POST",
        url: 'boats/request-batched-details',
        data: JSON.stringify($.extend(formData, selectedBoatsData)),
        dataType: "json",
        contentType: 'application/json'
      .done (response) ->
        $('#multiselected-request-for-details .processing').text(response.status).addClass('inline-loading').show()
        jobStatus = response.status
        jobID = response.id

#        $(document.body).append(response.google_conversion)
        if response.show_result_popup
         $('#enquiry_result_popup').displayPopup()

        intervalId = setInterval ( ->
          getStatus()
          if jobStatus != 'processing'
            clearInterval(intervalId)
        ), 1000

      .fail (response) ->
        $('#multiselected-request-for-details .processing').text(response.statusText).show()
