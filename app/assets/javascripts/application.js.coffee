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
#= require twitter/bootstrap
#= require jquery-ui/slider
#= require jquery.ui.touch-punch
#= require select2
#= require utils
#= require jquery.flexslider
#= require validetta
#= require_self
#= require_tree .

window.Rightboat = {}
Rightboat.validetta_options =
  custom :
    username :
      pattern : /^[a-zA-Z][\w\d\-\@\._]+$/,
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

$(document).ready ->
  $('[data-toggle=offcanvas]').click ->
    $('.row-offcanvas').toggleClass('active');
    if ($('.row-offcanvas').hasClass('active'))
      $(this).find('.glyphicon').removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-left')
    else
      $(this).find('.glyphicon').removeClass('glyphicon-chevron-left').addClass('glyphicon-chevron-right')



