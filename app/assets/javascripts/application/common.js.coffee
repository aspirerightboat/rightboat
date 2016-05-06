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
      if $target.data('method') == 'post' && $target.attr('id')
        href = location.href + '#' + $target.attr('id')
      else
        href = $target.attr('href')
        href = $target.data('target') if href == '#'
      if /my-rightboat\/saved-searches/.test(href)
        sessionStorage.setItem('saveSearch', 'true')
      else if history.pushState && window.location.href != href
        history.pushState({}, '', href)

    $loginBtn.trigger('click')
    return false
  true

window.scrollToTarget = (target) ->
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
    $('input[name=manufacturer], select', $form).select2('data', null)
    $('input[name=model], select', $form).select2('data', null)
    $('.year-slider, .length-slider, .price-slider', $form).each ->
      $(@).data('value0', '')
      $(@).data('value1', '')
      reinitSlider($(@))
    $($form[0].length_unit).select2 'val', 'ft'
    $($form[0].currency).select2 'val', 'GBP'
    $(@).closest('#advanced-search').find('h2').text('Advanced Search')
    $('.result-info').remove()
    false

  if sessionStorage.getItem('saveSearch') == 'true'
    $('.page-links .save-search a').trigger 'click'
  sessionStorage.removeItem('saveSearch')

  if (target = window.location.hash)
    if $(target).length
      if $(target).hasClass 'modal'
        $(target).modal('show')
      else if $(target).data('method') == 'post'
        $(target).click()
      else if $(target).hasClass('fav-link')
        window.favLink = $(target)
      else
        scrollToTarget(target)
    else if ['#berths_popup', '#finance_popup', '#insurance_popup'].indexOf(target) > -1
      setTimeout (-> $('[data-load-popup-id="' + target.replace('#', '') + '"]').click()), 10


  $('a[href*="#"]').click (e) ->
    $target = $($(@).attr('href').replace(/^\//, ''))
    if $target.length && !$target.hasClass('fav-link') && !$target.hasClass('filters-box')
      scrollToTarget($target)
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

  $('.simple-ajax-link').each ->
    $(@)
    .on 'ajax:beforeSend', (e) -> $(@).addClass('inline-loading')
    .on 'ajax:complete', (e) -> $(@).removeClass('inline-loading')
