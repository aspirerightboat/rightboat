$ ->
  $('.sync-select').each ->
    $sel = $(@)
    $sel.change ->
      $.getJSON($sel.data('action'), id: $sel.val(), (data) ->
        $sel2 = $('.' + $sel.data('target')).empty()
        if (blank = $sel.data('include-blank'))
          $sel2.append($('<option>').attr('value', '').text(blank))
        $.each data, ->
          $sel2.append($('<option>').attr('value', @[1]).text(@[0]))
      )