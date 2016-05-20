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
          $('#button-request-for-details').show()
        $('.selected-label').removeClass('unvisible')
        $('#number-selected').text(word_with_number('boat', selected.length) + ' selected')
        $('#multiselected-request-for-details').animate
          bottom: '0px'
      else
        $('#multiselected-request-for-details').animate
          bottom: '-95px'

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
        if jobStatus != 'processing'
          $('#multiselected-request-for-details .processing')
          .removeClass('inline-loading')
          $('#button-request-for-details').hide()
          $('.selected-label').addClass('unvisible')
          if jobStatus == 'ready'
            $('#multiselected-request-for-details .processing')
            .append("<span class='glyphicon glyphicon-download-alt'></span><a href='" + response.url + "'> Download File </a>")
            $('#download_iframe').attr('src', response.url)
          else
            $('#multiselected-request-for-details .processing')
            .append("<span class='glyphicon glyphicon-remove'></span> Something went wrong")


    clearMultiselect = () ->
      $('.multiselectable').removeClass('selected')
      Cookies.remove 'boats_multi_selected'
      $('#leads_message').attr('data-validetta', '').val('')
      clearInterval(intervalId)
      jobStatus = ''
      jobID = ''

    #
    # End of declaration
    #

    loadMultiSelected()

    $('.boat-thumb.thumbnail.multiselectable .tick').hover (e) ->
      if $('.multiselectable.selected').length == 0 # in selected mode
        $('#multiselected_explanation').animate
          bottom: '0px'
    , (e) ->
      $('#multiselected_explanation').animate
        bottom: '-50px'


    $('.boat-thumb.thumbnail.multiselectable .tick').on 'click', (e) ->
      e.stopPropagation()
      isSold = $(@).siblings('.sold').length > 0
      if isSold
        $(@).hide()
        return false
      if $(@).data('boat-message-required')
        $('#leads_message').attr('data-validetta', 'required')
      parent = $(@).parents('.boat-thumb.thumbnail.multiselectable')
      parent.toggleClass('selected')
      sendSelectedBoatsToCookies parent, $(@).data('boat-id')
      toggleBottomBar()

    $('.boat-thumb.thumbnail.multiselectable').on 'click', (e) ->
      return if $(e.target).hasClass('view-summary') # obey view summary button in anyt case

      if $('.multiselectable.selected').length > 0 # in selected mode
        e.preventDefault()
        isSold = $(@).children('.sold').length > 0
        return false if isSold
        $(@).toggleClass('selected')
        boat_id = $(@).children('.tick').data('boat-id')
        sendSelectedBoatsToCookies($(@), boat_id)
        toggleBottomBar()

    $('#button-request-for-details-clear').click ->
      clearMultiselect()
      toggleBottomBar()
      false

    $('#button-request-for-details').on 'click', (e) ->
      $('#leads_popup').displayPopup()

    $('.leads-form').simpleAjaxForm()
    .on 'ajax:before', (e) ->
      selectedBoats = readBoatsSelectedCookie()
      $('#has_account').val $('.leads-form #password').is(':visible')
      $('#boats_ids').val selectedBoats

    .on 'ajax:success', (e, data, status, xhr) ->
      clearMultiselect()
      json = xhr.responseJSON
      jobID = json.id
      jobStatus = json.status
      $(document.body).append(json.google_conversions) if json.google_conversions
      if json.show_result_popup
        $('#signup_email').val json.email
        $('#signup_title').val json.title
        $('#signup_first_name').val json.first_name
        $('#signup_last_name').val json.last_name
        $('#signup_phone').val json.full_phone_number
        $('#signup_lead_ids').val json.lead_ids
        $('#leads_result_popup').displayPopup()
      else
        $('#leads_popup').modal('hide')

      intervalId = setInterval ( ->
        getStatus()
        if jobStatus != 'processing'
          clearInterval(intervalId)
      ), 1000

    $('.signup-for-pdfs-form').simpleAjaxForm()
    .on 'ajax:success', (e, data, status, xhr) ->
      $('#lead_successfully_logged_popup').displayPopup()
