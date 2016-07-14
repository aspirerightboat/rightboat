$ ->
  $('.lead-form').each ->
    $form = $(@).simpleAjaxForm()
    $form
    .on 'ajax:before', (e) ->
      $('#has_account').val $('.lead-form #password').is(':visible')
    .on 'ajax:success', (e, data, status, xhr) ->
      json = xhr.responseJSON
      $(document.body).append(json.google_conversion)
      $('#download_iframe').attr('src', json.boat_pdf_url)
      $('#lead_message').val('')
      if json.signup_popup
        $('#lead_signup_popup').remove()
        $(document.body).append(json.signup_popup)
        $('#signup_lead_id').val json.lead_id
        $('#lead_signup_form').leadSignupForm()
        $('#lead_signup_popup').displayPopup()
      if json.downloading_popup
        $('#lead_downloading_popup').remove()
        $(document.body).append(json.downloading_popup)
        $('#lead_downloading_popup').displayPopup()

    $.fn.leadSignupForm = ->
      $form = @.simpleAjaxForm()
      $form.on 'ajax:before', (e) ->
        $('#signup_email').val($('#lead_email').val())
        $('#signup_title').val($('#lead_title').val())
        $('#signup_first_name').val($('#lead_first_name').val())
        $('#signup_last_name').val($('#lead_last_name').val())
        $('#signup_phone').val($('#lead_country_code').val() + ' ' + $('#lead_phone').val())
        $('#signup_boat').val($form.data('boat-slug'))
      .on 'ajax:success', (e, data, status, xhr) ->
        json = xhr.responseJSON
        $(document.body).append(json.google_conversion) if json.google_conversion

      $('.open-features-popup').click ->
        $('#features_popup').modal('show')
        false

  $('.hide-lead').on 'ajax:success', (e, data, status, xhr) ->
    $(@).closest('.boat-thumb-container').fadeOut()

  $('.unhide-leads').on 'ajax:success', (e, data, status, xhr) ->
    $('.boat-thumb-container').fadeIn()

  $('#request_qc_button').each ->
    $(@).click ->
      $('#qc_reason_popup').displayPopup()
      false
    $('#bad_quality_select').change(-> $('#bad_quality_comment').toggleClass('hidden', @.value != 'other')).change()
