$ ->
  $('.misspell-fixable-area').each ->
    $area = $(@)
    $popup = $('.misspell-fixable-popup')
    $input = $('.value-input', $popup)
    $save_btn = $('.save-btn', $popup)

    $(document.body).click (e) ->
      $popup.hide() if $(e.target).closest($popup).length == 0

    $('.esc-btn', $popup).click (e) -> $popup.hide(); false

    $('.titleize-btn', $popup).click ->
      val = $input.val().toLowerCase().replace(/(?:^|\s|-)\S/g, (c) -> c.toUpperCase())
      $input.val(val)
      false

    $save_btn.click ->
      $fixer = $popup.closest('.misspell-fixable')
      $save_btn.addClass('loading')
      name = $input.val()
      $save_btn.prop('disabled', true)
      $.post($fixer.data('url'), {name: name}, null, 'json')
        .done (data) ->
          if data.replaced_with_other
            $popup.detach().appendTo($(document.body))
            $fixer.remove()
          else
            $('ins', $fixer).text(name)
          $popup.hide()
          display_result('success', data.success)
        .fail (xhr, text_status) -> display_result('error', 'Error')
        .always ->
          $save_btn.removeClass('loading')
          $save_btn.prop('disabled', false)
      false

    $('.misspell-fixable ins').click ->
      $popup.detach().appendTo(@parentNode)
      setTimeout((-> $popup.show()), 0)
      $input.val(@textContent)

    $result = $('#misspell_fixable_result')
    hide_handle = null
    display_result = (result_class, text) ->
      $result.attr('class', result_class).text(text).show(200)
      clearTimeout(hide_handle) if hide_handle
      hide_handle = setTimeout((-> $result.hide(200)), 2000)
