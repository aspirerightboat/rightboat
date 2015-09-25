# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
# require turbolinks

#= require twitter/bootstrap/transition.js
#= require twitter/bootstrap/alert.js
#= require twitter/bootstrap/button.js
#= require twitter/bootstrap/carousel.js
#= require twitter/bootstrap/collapse.js
#= require twitter/bootstrap/dropdown.js
#= require twitter/bootstrap/modal.js
#= require twitter/bootstrap/tooltip.js
#= require twitter/bootstrap/popover.js
#= require twitter/bootstrap/scrollspy.js
#= require twitter/bootstrap/tab.js
#= require twitter/bootstrap/affix.js

#= require jquery-ui/slider
#= require jquery.ui.touch-punch
#= require select2
#= require jquery.multiple.select
#= require utils
#= require slick.min
#= require validetta
#= require_self
#= require_tree .

window.Rightboat = {}
Rightboat.validetta_options =
  custom :
    username :
      pattern : /^[a-zA-Z][\w@.-]+$/,
      errorMessage : "Only include a-z, A-Z, digits and underline."
  display: 'inline'

window.requireLogin = (e, disable_history)->
  $loginBtn = $('.user-login')
  if $loginBtn.length > 0
    e.preventDefault()
    unless disable_history
      href = $(e.target).prop('href')
      if history.pushState && window.location.href != href
        history.pushState({}, '', href)

    $loginBtn.trigger('click')
    return true
  false

scrollToTarget = (target) ->
  $('html, body').animate
    scrollTop: $(target).offset().top
  , 500

$(document).ready ->
  $('[data-toggle=offcanvas]').click ->
    $('.row-offcanvas').toggleClass('active');
    if ($('.row-offcanvas').hasClass('active'))
      $(this).find('.glyphicon').removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-left')
    else
      $(this).find('.glyphicon').removeClass('glyphicon-chevron-left').addClass('glyphicon-chevron-right')

  $('.reset-search-form').click ->
    form = this.form
    form.q.value = ''
    form.boat_type[0].checked = true
    $(form.currency).val('GBP').trigger('change')
    $(form.length_unit).val('ft').trigger('change')
    $('#price-slider, #length-slider').each ->
      opts = $(this).slider('option')
      $slider = $(this)
      $slider.slider('option', 'values', [opts.min, opts.max])
      alignSliderLabelPosition($slider)
    false

  $('[data-toggle="tooltip"]').tooltip()
  $('.toggle-about').click ->
    $this = $(this)
    $extended = $('.rb-extended')
    if $extended.is(':visible')
      $this.html 'more...'
      $extended.slideUp('slow')
    else
      $this.html 'less...'
      $extended.slideDown('slow')

  target = window.location.hash
  scrollToTarget(target) if $(target).length

  $('a[href*=#]').click (e) ->
    target = $(this).attr('href').replace(/^\//, '')
    scrollToTarget(target) if $(target).length

  $('.cool-select').select2()