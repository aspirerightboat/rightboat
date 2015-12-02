$ ->
  $('.checkbox-toggler').click ->
    $($(@).data('toggle-class')).toggleClass('hidden')