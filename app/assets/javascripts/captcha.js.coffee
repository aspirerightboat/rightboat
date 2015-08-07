$ ->
  $.fn.renderCaptcha = ->
    # jquery object should be form
    $this = $(this)
    $key = $this.find('#captcha_key')
    $img = $this.find('img.captcha-img')
    $submit = $this.find('[type="submit"]')

    $submit.attr('disabled', 'disabled')
    $.ajax
      url: '/captcha/new'
      method: 'GET'
      dataType: 'JSON'
    .success (resp)->
      $key.val(resp.key)
      $submit.removeAttr('disabled') if $img[0].complete
      $img.load ->
        $submit.removeAttr('disabled')
      $img.attr('src', '/captcha?' + $.param(key: resp.key))
    .error ->
      alert('Sorry, unexpected error occured.')

