$.fn.rbValidetta = (opts = {}) ->
  default_opts =
    display: 'inline'
  opts = $.extend(opts, default_opts)
  @.validetta(opts)

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
    $advSearch = $(@).closest('#advanced-search')
    $advSearch.find('h2').text('Advanced Search')
    $advSearch.find('.result-info').remove()
    $form = $advSearch.find('form')
    $('input[type=text]', $form).val('')
    $('input[type=checkbox]', $form).prop('checked', false)
    $('#manufacturers_picker, #models_picker, #countries_picker, #states_picker', $form).each -> @selectize.clear()

    $('.year-slider, .length-slider, .price-slider', $form).each ->
      $(@).data('value0', '')
      $(@).data('value1', '')
      reinitSlider($(@))
    false

  if sessionStorage.getItem('saveSearch') == 'true'
    $('#search_bar .save-search a').trigger 'click'
  sessionStorage.removeItem('saveSearch')

  # remove #_=_ in url after facebook auth
  if (window.location && window.location.hash == '#_=_')
    if (window.history && history.pushState)
      window.history.pushState("", document.title, window.location.pathname);

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

  curPopup = null
  $.fn.displayPopup = ->
    curPopup.modal('hide') if curPopup
    curPopup = @.modal('show')

  $('.hide-parent').click ->
    $(@).closest($(@).data('hide-parent')).hide(200)

  $('.simple-ajax-link').each ->
    $(@)
    .on 'ajax:beforeSend', (e) -> $(@).addClass('inline-loading')
    .on 'ajax:complete', (e) -> $(@).removeClass('inline-loading')
