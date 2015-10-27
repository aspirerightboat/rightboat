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
#= require selectize.min
#= require jquery.multiple.select
#= require utils
#= require slick.min
#= require photoswipe.min
#= require photoswipe-ui-default.min
#= require validetta
#= require jquery.remotipart
#= require cocoon
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
  $loginBtn = $('.login-top')
  if $loginBtn.length > 0
    e.preventDefault()
    $target = $(e.target)

    unless disable_history
      if $target.data('method') == 'post'
        href = location.href + '#' + $target.attr('id')
      else
        href = $target.attr('href')
        href = $target.data('target') if href == '#'
      if history.pushState && window.location.href != href
        history.pushState({}, '', href)

    $loginBtn.trigger('click')
    return false
  true

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
  if $(target).length
    if $(target).hasClass 'modal'
      $(target).modal('show')
    else if $(target).data('method') == 'post'
      $(target).click()
    else if $(target).hasClass('fav-link')
      window.favLink = $(target)
    else
      if target == '#about'
        $('.rb-extended').slideDown()
        $('.toggle-about').html 'less...'
      scrollToTarget(target)

  $('a[href*=#]').click (e) ->
    target = $(this).attr('href').replace(/^\//, '')
    if target == '#about'
      $('.rb-extended').slideDown()
      $('.toggle-about').html 'less...'
    unless $(target).length && $(target).hasClass('fav-link')
      scrollToTarget(target) if $(target).length

  $('.cool-select').select2()

  $('.modal').on 'hidden.bs.modal', ->
    $(this).find('input[type="text"], input[type="email"], input[type="password"], textarea').val('')
    $(this).find('select').select2 'val', ''
    $(this).find('.select-title').val('')
    $(this).find('.selectize-input input').val('').attr('placeholder', 'Title').css
      left: 0
      opacity: 1
      position: 'relative'
      width: 'auto'
    $(this).find('.selectize-input > div').html('')

$.fn.initTitleSelect = ->
  @.selectize(create: true, createOnBlur: true)
$ ->
  $('.select-title').initTitleSelect()

$ ->
  curPopup = null
  $.fn.displayPopup = ->
    curPopup.modal('hide') if curPopup
    curPopup = @
    @.modal('show')

$ ->
  $('#confirm_email_popup').each ->
    $(@).displayPopup()