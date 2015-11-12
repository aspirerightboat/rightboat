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
#= require jquery.datetimepicker.full.min
#= require jquery.ui.touch-punch
#= require select2
#= require selectize.min
#= require js-cookie
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

$.fn.rbValidetta = (opts = {}) ->
  default_opts =
    display: 'inline'
    custom :
      username :
        pattern : /^[a-zA-Z][\w@.-]+$/,
        errorMessage : "Only include a-z, A-Z, digits and underline."
  @.validetta($.extend(default_opts, opts))

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
  $('[data-toggle="tooltip"]').tooltip()
  $('[data-toggle=offcanvas]').click ->
    $('.row-offcanvas').toggleClass('active');
    if ($('.row-offcanvas').hasClass('active'))
      $(this).find('.icon').removeClass('icon-right-open').addClass('icon-left-open')
    else
      $(this).find('.icon').removeClass('icon-left-open').addClass('icon-right-open')

  ###
  $('.reset-search-form').click ->
    $form = $('#search-hub-form form')
    $form.find('#search-input').val('')
    $form.find('#boat_type_all').click()
    $form.find('.price-slider, .length-slider').each ->
      $this = $(this)
      for i in [0, 1]
        $(this).data('value' + i, '')
      reinitSlider($this)

    $form.find('#s2id_currency').select2 'val', 'GBP'
    $form.find('#s2id_length_unit').select2 'val', 'ft'
    false

  $('.toggle-about').click ->
    $this = $(this)
    $extended = $('.rb-extended')
    if $extended.is(':visible')
      $this.html 'more...'
      $extended.slideUp('slow')
    else
      $this.html 'less...'
      $extended.slideDown('slow')
  ###

  target = window.location.hash
  if $(target).length
    if $(target).hasClass 'modal'
      $(target).modal('show')
    else if $(target).data('method') == 'post'
      $(target).click()
    else if $(target).hasClass('fav-link')
      window.favLink = $(target)
    else
      ###
      if target == '#about'
        $('.rb-extended').slideDown()
        $('.toggle-about').html 'less...'
      ###
      scrollToTarget(target)

  $('a[href*=#]').click (e) ->
    target = $(this).attr('href').replace(/^\//, '')
    ###
    if target == '#about'
      $('.rb-extended').slideDown()
      $('.toggle-about').html 'less...'
    ###
    if $(target).length && !$(target).hasClass('fav-link')
      e.preventDefault()
      scrollToTarget(target)
      return false

  $('.cool-select').select2()

  $.fn.resetForm = ->
    $('form', @).reset()
    $('select', @).select2 'val', ''
    $('.selectize-input input', @).val('').attr('placeholder', 'Title').css
      left: 0
      opacity: 1
      position: 'relative'
      width: 'auto'
    $('.selectize-input > div', @).html('')

$.fn.initTitleSelect = ->
  @.selectize(create: true, createOnBlur: true)
$ ->
  $('.select-title').initTitleSelect()

$ ->
  curPopup = null
  $.fn.displayPopup = ->
    curPopup.modal('hide') if curPopup
    curPopup = @.modal('show')
