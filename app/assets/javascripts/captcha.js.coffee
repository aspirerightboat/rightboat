$ ->
  $.fn.renderCaptcha = ->
    $form = $(this)
    $img = $('.captcha-img', $form)
    $.get '/captcha/new', ->
      $img.attr('src', '/captcha?' + (+new Date()))

