$ ->
  $('.load-popup').click ->
    $link = $(@)

    if $link.hasClass('open-login-popup') && $('.login-button').length
      return true

    popup_id = $link.data('load-popup-id')
    popup_url = $link.data('load-popup-url')

    if !$('#' + popup_id).length
      if !$link.hasClass('inline-loading')
        $link.addClass('inline-loading')
        $.getScript(popup_url)
        .done -> $('#' + popup_id).displayPopup()
        .always -> $link.removeClass('inline-loading')
    else
      $('#' + popup_id).displayPopup()

    false
