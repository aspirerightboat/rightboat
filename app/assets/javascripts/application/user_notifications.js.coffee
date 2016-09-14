$ ->
  $('.toggle-saved-searches-alerts').each ->
    $('input[type=checkbox]', @).click ->
      $('#saved_searches_row').slideToggle(@checked)

    $(@).on 'ajax:success', '.toggle-alert', (e, data) ->
      $(e.target)
      .toggleClass('label-success', data.alert)
      .toggleClass('label-default', !data.alert)
      .text(if data.alert then 'Alert On' else 'No Alert')
      false
