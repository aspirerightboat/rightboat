$ ->
  $('.toggle-saved-searches-alerts input[type=checkbox]').on 'click', (e, data, status, xhr) ->
    if $(@).prop('checked') == false
      $('.toggle-saved-searches-alerts .toggle-alert').addClass('label-default').removeClass('label-success')
      $('.toggle-saved-searches-alerts .toggle-alert').text('No Alert')
      $('input[type="hidden"].saved-search-field').val(false)
    else
      $('.toggle-saved-searches-alerts .toggle-alert').addClass('label-success').removeClass('label-default')
      $('.toggle-saved-searches-alerts .toggle-alert').text('Alert On')
      $('input[type="hidden"].saved-search-field').val(true)

  $('.toggle-saved-searches-alerts .toggle-alert').on 'click', (e, data, status, xhr) ->
    e.preventDefault()
    if  $('.toggle-saved-searches-alerts input[type=checkbox]').prop('checked') == true
      if $(@).hasClass('label-default')
        $(@).addClass('label-success').removeClass('label-default')
        $(@).text('Alert On')
        $(@).next('input[type="hidden"]').val(true)
      else
        $(@).addClass('label-default').removeClass('label-success')
        $(@).text('No Alert')
        $(@).next('input[type="hidden"]').val(false)
