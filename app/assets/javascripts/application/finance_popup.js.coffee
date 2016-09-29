$ ->
  $('.finance-popup-link').each ->
    $(@).simpleAjaxLink().loadPopupOnce()
    .on 'ajax:success', (e, data) ->
      if data.redirect_to
        window.location = data.redirect_to
        return
      $form = $('#finance_form')
      $('.select-general', $form).generalSelect()
      $('.select-currency', $form).currencySelect()
      $('.country-select', $form).countrySelect()
      $form.simpleAjaxForm()
      .on 'ajax:success', (e, data) ->
        $('#finance_result_popup').remove()
        $(data.show_popup).appendTo(document.body).displayPopup()
