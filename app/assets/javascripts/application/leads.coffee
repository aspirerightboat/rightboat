$ ->
  $('.lead-form').each ->
    $form = $(@).simpleAjaxForm()
    $form
    .on 'ajax:before', (e) ->
      $('#has_account').val $('.lead-form #password').is(':visible')
    .on 'ajax:success', (e, data) ->
      $(document.body).append(data.google_conversion)
      $('#download_iframe').attr('src', data.boat_pdf_url)
      $('#lead_message').val('')
      if data.signup_popup
        $('#lead_signup_popup').remove()
        $(document.body).append(data.signup_popup)
        $('#signup_lead_id').val data.lead_id
        $('#lead_signup_form').leadSignupForm()
        $('#lead_signup_popup').displayPopup()
      if data.downloading_popup
        $('#lead_downloading_popup').remove()
        $(document.body).append(data.downloading_popup)
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
      .on 'ajax:success', (e, data) ->
        $(document.body).append(data.google_conversion) if data.google_conversion

      $('.open-features-popup').click ->
        $('#features_popup').modal('show')
        false

  $('.hide-lead').on 'ajax:success', ->
    $(@).closest('.boat-thumb-container').fadeOut()

  $('.unhide-leads').on 'ajax:success', ->
    $('.boat-thumb-container').fadeIn()

  $('#request_qc_button').each ->
    $(@).click ->
      $('#qc_reason_popup').displayPopup()
      false
    $('#bad_quality_select').change(-> $('#bad_quality_comment').toggleClass('hidden', @.value != 'other')).change()
