$ ->
  if $('.multiselectable').length
    file_url = ''
    jobID = ''
    jobStatus = ''
    intervalId = null

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
        $('#multiselected-request-for-details .processing').text(response.status).addClass('inline-loading').show()
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
      clearInterval(intervalId)
      jobStatus = ''
      jobID = ''
      false

    $('#button-request-for-details').on 'click', (e) ->
      $('#enquiries_popup').displayPopup()

    $('.enquiries-form').simpleAjaxForm()
    .on 'ajax:before', (e) ->
      selectedBoats = JSON.parse(Cookies.get 'boats_multi_selected').boats_ids
      $('#has_account').val $('.enquiries-form #password').is(':visible')
      $('#boats_ids').val selectedBoats
    .on 'ajax:success', (e, data, status, xhr) ->
      Cookies.remove 'boats_multi_selected'
      json = xhr.responseJSON
      jobID = json.id
      jobStatus = json.status
      $(document.body).append(json.google_conversions) if json.google_conversions
      if json.show_result_popup
        $('#enquiries_result_popup #signup_email').val json.email
        $('#enquiries_result_popup #signup_title').val json.title
        $('#enquiries_result_popup #signup_first_name').val json.first_name
        $('#enquiries_result_popup #signup_last_name').val json.last_name
        $('#enquiries_result_popup #signup_phone').val json.full_phone_number
        $('#enquiries_result_popup').displayPopup()
      else
        $('#enquiries_popup').modal('hide')

      intervalId = setInterval ( ->
        getStatus()
        if jobStatus != 'processing'
          clearInterval(intervalId)
      ), 1000

    $('.signup-for-pdfs-form').simpleAjaxForm()
    .on 'ajax:success', (e, data, status, xhr) ->
      $('#enquiry_successfully_logged_popup').displayPopup()
