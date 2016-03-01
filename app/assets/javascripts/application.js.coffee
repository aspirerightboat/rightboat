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
#= require dropzone
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
  @.validetta($.extend(opts, default_opts))

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

$ ->
  $('[data-toggle="tooltip"]').tooltip()
  $('[data-toggle="popover"]').popover({html: true})
  $('[data-toggle=offcanvas]').click ->
    $('.row-offcanvas').toggleClass('active');
    if ($('.row-offcanvas').hasClass('active'))
      $(this).find('.icon').removeClass('icon-right-open').addClass('icon-left-open')
    else
      $(this).find('.icon').removeClass('icon-left-open').addClass('icon-right-open')

  $('.reset-adv-search').click ->
    $form = $(@).closest('#advanced-search').find('form')
    if window.countries_options
      $('.multiple-country-select').select2("destroy").html(window.countries_options)
      $('.multiple-country-select').select2()
    $('input[type=text]', $form).val('')
    $('input[type=checkbox]', $form).prop('checked', false)
    $('input[name=manufacturer_model], select', $form).select2('data', null)
    $('.year-slider, .length-slider, .price-slider', $form).each ->
      $(@).data('value0', '')
      $(@).data('value1', '')
      reinitSlider($(@))
    $($form[0].length_unit).select2 'val', 'ft'
    $($form[0].currency).select2 'val', 'GBP'
    $(@).closest('#advanced-search').find('h2').text('Advanced Search')
    $('.result-info').remove()
    false

  target = window.location.hash
  if $(target).length
    if $(target).hasClass 'modal'
      $(target).modal('show')
    else if $(target).data('method') == 'post'
      $(target).click()
    else if $(target).hasClass('fav-link')
      window.favLink = $(target)
    else
      scrollToTarget(target)
  else if ['#berths-popup', '#finance-popup', 'insurance-popup'].indexOf(target) > -1 and $('.login-top').length > 0
    $('#login_popup').modal('show')

  $('a[href*="#"]').click (e) ->
    target = $(this).attr('href').replace(/^\//, '')
    if $(target).length && !$(target).hasClass('fav-link')
      scrollToTarget(target)
      false

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

$ ->
  $('.hide-parent').click ->
    $(@).closest($(@).data('hide-parent')).hide(200)