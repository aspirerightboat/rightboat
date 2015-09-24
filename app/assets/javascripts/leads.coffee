$ ->
  $('#request_qc_button').each ->
    $(@).click ->
      $('#qc_reason_popup').modal('show')
      false
    $('#bad_quality_select').change(-> $('#bad_quality_comment').toggleClass('hidden', @.value != 'other')).change()
