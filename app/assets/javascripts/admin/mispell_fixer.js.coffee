$ ->
  $('.misspell-fixing-area').each ->
    $fixing_area = $(@)
    $fixer_popup = $('.misspell-fixer-popup')
    $fixer_input = $('.value-input', $fixer_popup)
    $save_btn = $('.save-btn', $fixer_popup)
    $error = $('.error', $fixer_popup)
    $fixing_area.click (e) ->
      $fixer_popup.hide() if $(e.target).closest($fixer_popup).length == 0
      false
    $('.esc-btn', $fixer_popup).click (e) -> $fixer_popup.hide(); false
    $('.titleize-btn', $fixer_popup).click ->
      val = $fixer_input.val().toLowerCase().replace(/(?:^|\s|-)\S/g, (c) -> c.toUpperCase())
      $fixer_input.val(val)
      false

    $save_btn.click ->
      $fixer = $fixer_popup.closest('.misspell-fixer')
      url = '/admin/' + $fixer.data('collection') + '/' + $fixer.data('id') + '/fix_name'
      $save_btn.addClass('loading')
      name = $fixer_input.val()
      $save_btn.prop('disabled', true)
      $.post(url, {name: name}, null, 'json')
        .done (data) ->
          if data.replaced_with_other
            $fixer_popup.detach().appendTo($fixer.parent())
            $fixer.remove()
          else
            $fixer_popup[0].previousSibling.nodeValue = name
            $fixer_popup.hide()
        .fail (xhr, text_status) -> $error.text(text_status)
        .always ->
          $save_btn.removeClass('loading')
          $save_btn.prop('disabled', false)
      false

    $('.misspell-fixer').click ->
      $fixer = $(@)
      return if $fixer.hasClass('loading') || $fixer_popup.is(':visible')
      $fixer.addClass('loading')
      $fixer_popup.hide()
      url = '/admin/' + $fixer.data('collection') + '/' + $fixer.data('id') + '/fetch_name'
      $.get(url, null, null, 'text')
        .done (data) ->
          $fixer_popup.detach().appendTo($fixer).show()
          $fixer_input.val(data)
          $error.text('')
        .always -> $fixer.removeClass('loading')
