$ ->
  $('.misspell-fixable-area').each ->
    $area = $(@)
    $popup = $('.misspell-fixable-popup')
    $input = $('.value-input', $popup)
    $save_btn = $('.save-btn', $popup)
    $error = $('.error', $popup)
    $area.click (e) ->
      $popup.hide() if $(e.target).closest($popup).length == 0
      false
    $('.esc-btn', $popup).click (e) -> $popup.hide(); false
    $('.titleize-btn', $popup).click ->
      val = $input.val().toLowerCase().replace(/(?:^|\s|-)\S/g, (c) -> c.toUpperCase())
      $input.val(val)
      false

    $save_btn.click ->
      $fixer = $popup.closest('.misspell-fixable')
      url = '/admin/' + $fixer.data('collection') + '/' + $fixer.data('id') + '/fix_name'
      $save_btn.addClass('loading')
      name = $input.val()
      $save_btn.prop('disabled', true)
      $.post(url, {name: name}, null, 'json')
        .done (data) ->
          if data.replaced_with_other
            $popup.detach().appendTo($fixer.parent())
            $fixer.remove()
          else
            $popup[0].previousSibling.nodeValue = name
            $popup.hide()
        .fail (xhr, text_status) -> $error.text(text_status)
        .always ->
          $save_btn.removeClass('loading')
          $save_btn.prop('disabled', false)
      false

    $('.misspell-fixable').click ->
      $fixable = $(@)
      return if $fixable.hasClass('loading') || $popup.is(':visible')
      $fixable.addClass('loading')
      url = '/admin/' + $fixable.data('collection') + '/' + $fixable.data('id') + '/fetch_name'
      $.get(url, null, null, 'text')
        .done (data) ->
          $popup.detach().appendTo($fixable).show()
          $input.val(data)
          $error.text('')
        .always -> $fixable.removeClass('loading')
