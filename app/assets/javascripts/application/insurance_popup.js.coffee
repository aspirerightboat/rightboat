$ ->
  $('.insurance-popup-link').each ->
    $(@).simpleAjaxLink().loadPopupOnce()
    .on 'ajax:success', ->
      $form = $('#insurance_form')
      $('.select-general', $form).generalSelect()
      $('.select-currency', $form).currencySelect()
      $('.country-select', $form).countrySelect()
      $form.simpleAjaxForm()
      .on 'ajax:success', (e, data) ->
        $('#insurance_result_popup').remove()
        $(data.show_popup).appendTo(document.body).displayPopup()
