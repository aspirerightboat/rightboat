$ ->
  $('.enquiry-form').each ->
    $form = $(@).simpleAjaxForm()
    $form
    .on 'ajax:before', (e) ->
      $('#has_account').val $('.enquiry-form #password').is(':visible')
    .on 'ajax:success', (e, data, status, xhr) ->
      json = xhr.responseJSON
      $(document.body).append(json.google_conversion)
      $('#download_iframe').attr('src', json.boat_pdf_url)
      $('#enquiry_message').val('')
      if json.show_result_popup
        $('#signup_enquiry_id').val json.enquiry_id
        $('#enquiry_result_popup').displayPopup()
      else
        $('#enquiry_popup_downloading').displayPopup()
        setTimeout (-> $('#enquiry_popup_downloading').modal('hide')), 4000

    $('#enquiry_signup_form')
    .on 'ajax:before', (e) ->
      $('#signup_email').val($('#enquiry_email').val())
      $('#signup_title').val($('#enquiry_title').val())
      $('#signup_first_name').val($('#enquiry_first_name').val())
      $('#signup_last_name').val($('#enquiry_last_name').val())
      $('#signup_phone').val($('#enquiry_country_code').val() + ' ' + $('#enquiry_phone').val())
      $('#signup_boat').val($form.data('boat-slug'))
    .on 'ajax:success', (e, data, status, xhr) ->
      json = xhr.responseJSON
      $(document.body).append(json.google_conversion) if json.google_conversion

    $('.open-features-popup').click ->
      $('#features_popup').modal('show')
      false

  $('.hide-enquiry').on 'ajax:success', (e, data, status, xhr) ->
    $(@).closest('.boat-thumb-container').fadeOut()

  $('.unhide-enquires').on 'ajax:success', (e, data, status, xhr) ->
    $('.boat-thumb-container').fadeIn()
