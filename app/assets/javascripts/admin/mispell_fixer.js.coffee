$ ->
  $('.misspell-fixable-area').each ->
    $area = $(@)

    $(document.body).click (e) ->
      $('.fixing-popup').hide() if $(e.target).closest('.fixing-popup').length == 0

    $('.fixing-popup .esc').click (e) -> $(e.target).closest('.fixing-popup').hide(); false


    $naming_popup = $('.misspell-fixable-popup')
    $input = $('.value-input', $naming_popup)
    $save_btn = $('.save-btn', $naming_popup)
    $misp_check = $('.create-misspell-input', $naming_popup)

    $('.misspell-fixable ins').click ->
      $fixable = $(@parentNode)
      $naming_popup.detach().appendTo($fixable)
      setTimeout((-> $naming_popup.show()), 0)
      $input.val(@textContent)
      $misp_check.prop('checked', true)
      type = $fixable.data('type').toLowerCase()
      type_id = $fixable.data('id')
      $('.view-boats-btn').attr('href', '/admin/boats?q[status]=active&q[' + type + '_id_eq]=' + type_id)

    $save_btn.click ->
      $fixable = $naming_popup.closest('.misspell-fixable')
      $save_btn.addClass('loading').prop('disabled', true)
      name = $input.val()
      url = '/admin/makers_models/fix_name?class=' + $fixable.data('type') + '&id=' + $fixable.data('id')
      $.post(url, {name: name, create_misspellings: $misp_check.val()}, null, 'json')
        .done (data) ->
          if data.replaced_with_other
            $naming_popup.detach().appendTo($(document.body))
            $fixable.remove()
          else
            $('ins', $fixable).text(name)
          $naming_popup.hide()
          display_result('success', data.success)
        .fail (xhr, text_status) -> display_result('error', 'Error')
        .always -> $save_btn.removeClass('loading').prop('disabled', false)
      false

    $('.titleize-btn', $naming_popup).click ->
      val = $input.val().toLowerCase().replace(/(?:^|\s|-)\S/g, (c) -> c.toUpperCase())
      $input.val(val)
      false


    $split_popup = $('#split_popup')
    $m1_input = $('#maker1_input')
    $m2_input = $('#maker2_input')
    $split_btn = $('#split_btn')

    $('.show-split-popup').click ->
      $fixable = $(@).closest('.misspell-fixable')
      $split_popup.detach().appendTo($fixable)
      setTimeout((-> $split_popup.show()), 0)
      $m1_input.val($fixable.find('ins').text())
      $m2_input.val('')
      false

    $split_btn.click ->
      $fixable = $split_popup.closest('.misspell-fixable')
      $split_btn.addClass('loading').prop('disabled', true)
      part1 = $m1_input.val()
      part2 = $m2_input.val()
      url = '/admin/makers_models/split_name?id=' + $fixable.data('id')
      $.post(url, {part1: part1, part2: part2}, null, 'json')
      .done (data) ->
        $model_fixables = $fixable.closest('td').next().find('.misspell-fixable')
        if data.replaced_with_other
          $split_popup.detach().appendTo($(document.body))
          $fixable.remove()
        $('ins', $fixable).text(data.maker_name)
        $.each $model_fixables, (i, mfixable) ->
          id = $(mfixable).data('id')
          new_name = data.model_names[id]
          if new_name
            $(mfixable).find('ins').text(new_name)
          else
            $(mfixable).remove()
        $split_popup.hide()
        display_result('success', data.success)
      .fail (xhr, text_status) -> display_result('error', 'Error')
      .always -> $split_btn.removeClass('loading').prop('disabled', false)
      false

    $('#word_right_btn').click ->
      tokens = $m1_input.val().split(' ')
      last = tokens.pop()
      $m1_input.val(tokens.join(' ').trim())
      $m2_input.val((last + ' ' + $m2_input.val()).trim())
      false


    $result = $('#misspell_fixable_result')
    hide_handle = null
    display_result = (result_class, text) ->
      $result.attr('class', result_class).text(text).show(200)
      clearTimeout(hide_handle) if hide_handle
      hide_handle = setTimeout((-> $result.hide(200)), 2000)
