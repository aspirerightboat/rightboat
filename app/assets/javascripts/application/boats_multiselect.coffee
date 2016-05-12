$ ->
  if $('.multiselectable').length
    file_url = ''
    jobID = ''
    jobStatus = ''
    intervalId = null
    readBoatsSelectedCookie = () ->
      return (Cookies.get 'boats_multi_selected') && JSON.parse(Cookies.get 'boats_multi_selected').boats_ids || []

    toggleBottomBar = () ->
      selected = readBoatsSelectedCookie()
      if selected.length > 0
        if jobStatus.length == 0
          $('#multiselected-request-for-details .processing').text('').hide()
          $('#multiselected-request-for-details #button-request-for-details').show()
        $('#multiselected-request-for-details #number-selected').text(word_with_number('boat', selected.length) + ' selected')
        $('#multiselected-request-for-details').animate
          bottom: '0px'
      else
        $('#multiselected-request-for-details').animate
          bottom: '-90px'

    word_with_number = (word, number) ->
      if number == 1
        return(number + ' ' + word)
      else
        return(number + ' ' + word + 's')

    sendSelectedBoatsToCookies = (parent, boat_id) ->
      array = readBoatsSelectedCookie()
      if parent.hasClass('selected')
        array.push boat_id
      else
        array = array.filter (el) ->
          return el != boat_id

      Cookies.set 'boats_multi_selected', JSON.stringify({'boats_ids' : array})

    loadMultiSelected = () ->
      selectedBoats = []

      selectedBoats = readBoatsSelectedCookie()

      $.each selectedBoats, (_, id) ->
        $('.tick[data-boat-id=' + id + ']').parents('.multiselectable').addClass('selected')

      if selectedBoats.length > 0
        toggleBottomBar()

    getStatus = () ->
      $.ajax
        type: "get",
        url: '/batch_upload_jobs/' + jobID,
      .done (response) ->
        $('#multiselected-request-for-details .processing').addClass('inline-loading').show()
        jobStatus = response.status
        if jobStatus != 'processing' && jobStatus == 'ready'
          $('#multiselected-request-for-details .processing')
          .removeClass('inline-loading')
          .append("<span class='glyphicon glyphicon-download-alt'></span><a href='" + response.url + "'> Download File </a>")
          $('#download-iframe').prop('src', response.url)
          $('#multiselected-request-for-details #button-request-for-details').hide()
          jobStatus = ''

    #
    # End of declaration
    #

    loadMultiSelected()

    $('.boat-thumb.thumbnail.multiselectable .tick').on 'click', (e) ->
      e.stopPropagation()
      e.preventDefault()
      if $(@).data('boat-message-required')
        $('#enquiries_popup #message').attr('data-validetta', 'required')
      parent = $(@).parents('.boat-thumb.thumbnail.multiselectable')
      parent.toggleClass('selected')
      sendSelectedBoatsToCookies parent, $(@).data('boat-id')
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
      $('#enquiries_popup #message').attr('data-validetta', '')
      clearInterval(intervalId)
      jobStatus = ''
      jobID = ''
      false

    $('#button-request-for-details').on 'click', (e) ->
      $('#enquiries_popup').displayPopup()

    $('.enquiries-form').simpleAjaxForm()
    .on 'ajax:before', (e) ->
      selectedBoats = readBoatsSelectedCookie()
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
        $('#enquiries_result_popup #signup_enquiries_ids').val json.enquiries_ids
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
