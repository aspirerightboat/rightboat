$.fn.loadPopupOnce = ->
  @.each ->
    $(@)
    .on 'ajax:before', (e) ->
      if (popup = $(@).data('loaded-popup'))
        popup.displayPopup()
        false
    .on 'ajax:success', (e, data) ->
      if data.show_popup
        $popup = $(data.show_popup).appendTo(document.body).displayPopup()
        $(@).data('loaded-popup', $popup)
