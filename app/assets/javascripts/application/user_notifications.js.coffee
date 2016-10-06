$ ->
  $('.toggle-saved-searches-alerts').each ->
    $ssRow = $('#saved_searches_row')
    $('input[type=checkbox]', @).click ->
      if @checked then $ssRow.slideDown() else $ssRow.slideUp()

    $(@).on 'ajax:success', '.toggle-alert', (e, data) ->
      $(e.target)
      .toggleClass('label-success', data.alert)
      .toggleClass('label-default', !data.alert)
      .text(if data.alert then 'Alert On' else 'No Alert')
      false
