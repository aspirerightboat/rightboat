$ ->
# $('#enquiry_popup').on 'show.bs.modal', ->
#   $('form', @).renderCaptcha()

  $('.enquiry-form').each ->
    $form = $(@)
    $form
    .on 'ajax:before', (e) ->
      $phone = $('#enquiry_phone')
      if $phone.is(':visible') && !$phone.val() && !$('#phone_popup').is(':visible')
        $('#phone_popup').modal('show')
        false
    .on 'ajax:success', (e, data, status, xhr) ->
      if xhr.responseJSON.show_result_popup
        $('#enquiry_result_popup').displayPopup()
#          $('#logged_in_result').toggleClass('hidden', !loggedIn)
#          $('#logged_out_result').toggleClass('hidden', loggedIn)

#          $('#broker_name').html(enquiry.broker.name)
#          $('#broker_phone').html(enquiry.broker.phone).before(', ') if enquiry.broker.phone
#
#          $('#pdf_link').attr('href', enquiry.boat_pdf)

#          any_similar = enquiry.similar_boats.length > 0
#          if enquiry.similar_link
#            $('.similar-boats-link a', @).attr('href', enquiry.similar_link)
#          $('.similar-boats-link', @).toggle(any_similar)
#          $similar_boats = $('.similar-boats', @).empty().toggle(any_similar)
#          $.each enquiry.similar_boats, ->
#            $similar_boats.append(
#              $('<div class="col-xs-4 col-sm-3 col-lg-2">').append(
#                $('<a>').attr('href', '/boats-for-sale/' + @slug).append(
#                  $('<img>').attr('src', @primary_image.mini))))

    $('#enquiry_result_popup').on 'hidden.bs.modal', ->
      window.location = location.href if $form.data('just-logged-in')

    $('.open-features-popup').click ->
      loggedIn = !$('.user-login').length || $form.data('just-logged-in')
      if (!loggedIn)
        $('#features_popup').modal('show')
        false

    $('.enquiry-without-phone').click ->
      $('.enquiry-form').submit()

    $('.signup-for-pdf-form').on 'ajax:before', (e) ->
      $('#signup_email').val($('#enquiry_email').val())
      $('#signup_title').val($('#enquiry_title').val())
      $('#signup_first_name').val($('#enquiry_first_name').val())
      $('#signup_last_name').val($('#enquiry_last_name').val())
      $('#signup_phone').val($('#enquiry_country_code').val() + ' ' + $('#enquiry_phone').val())
      $('#signup_boat').val($form.data('boat-slug'))

  $('.hide-enquiry').on 'ajax:success', (e, data, status, xhr) ->
    $(@).closest('.boat-thumb-container').fadeOut()

  $('.unhide-enquires').on 'ajax:success', (e, data, status, xhr) ->
    $('.boat-thumb-container').fadeIn()

