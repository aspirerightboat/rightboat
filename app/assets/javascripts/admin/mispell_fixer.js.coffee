$ ->
  $('.misspell-fixable-area').each ->
    $area = $(@)
    $popup = $('.misspell-fixable-popup')
    $input = $('.value-input', $popup)
    $save_btn = $('.save-btn', $popup)

    $(document.body).click (e) ->
      $popup.hide() if $(e.target).closest($popup).length == 0

    $('.esc', $popup).click (e) -> $popup.hide(); false

    $('.titleize-btn', $popup).click ->
      val = $input.val().toLowerCase().replace(/(?:^|\s|-)\S/g, (c) -> c.toUpperCase())
      $input.val(val)
      false

    $save_btn.click ->
      $fixer = $popup.closest('.misspell-fixable')
      $save_btn.addClass('loading')
      name = $input.val()
      $save_btn.prop('disabled', true)
      url = '/admin/makers_models/fix_name?class=' + $fixer.data('type') + '&id=' + $fixer.data('id')
      $.post(url, {name: name}, null, 'json')
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
      $mf = $(@parentNode)
      $popup.detach().appendTo($mf)
      setTimeout((-> $popup.show()), 0)
      $input.val(@textContent)
      type = $mf.data('type').toLowerCase()
      type_id = $mf.data('id')
      $('.view-boats-btn').attr('href', '/admin/boats?q[status]=active&q[' + type + '_id_eq]=' + type_id)

    $result = $('#misspell_fixable_result')
    hide_handle = null
    display_result = (result_class, text) ->
      $result.attr('class', result_class).text(text).show(200)
      clearTimeout(hide_handle) if hide_handle
      hide_handle = setTimeout((-> $result.hide(200)), 2000)
