$ ->
  $.fn.stripeCardForm = (onCardSaved) ->
    $card_form = @
    $('.card-fields-number input', $card_form).payment('formatCardNumber')
    $('.card-fields-expire input', $card_form).payment('formatCardExpiry')
    $('.card-fields-cvc input', $card_form).payment('formatCardCVC')
    $card_submit = $('button[type=submit]', $card_form)

    display_error = (msg) ->
      $card_form.showFormError(msg)
      $card_submit.prop('disabled', false)

    $card_form.submit (event) ->
      $card_submit.prop('disabled', true)

      card_number = $('[data-stripe=number]', $card_form).val()
      expiry = $('[data-stripe=exp]', $card_form).payment('cardExpiryVal')
      cvc = $('[data-stripe=cvc]', $card_form).val()
      card_type = $.payment.cardType(card_number)
      if !$.payment.validateCardNumber(card_number)
        display_error('Your card number is incorrect')
        return false
      if !$.payment.validateCardExpiry(expiry.month, expiry.year)
        display_error('Your expiry date is incorrect')
        return false
      if !$.payment.validateCardCVC(cvc, card_type)
        display_error('Your CVC is incorrect')
        return false

      Stripe.card.createToken $card_form, (status, response) ->
        if response.error
          display_error(response.error.message)
        else
          params =
            stripe_token: response.id,
            brand: response.card.brand,
            country_iso: response.card.country,
            last4: response.card.last4,
            dynamic_last4: response.card.dynamic_last4,
            exp_month: response.card.exp_month,
            exp_year: response.card.exp_year
          $.post($card_form.attr('action'), params)
          .done (data) -> onCardSaved($card_form, data)
          .fail (xhr) ->
            json = xhr.responseJSON
            msg = if json then json.error else 'Something went wrong'
            $card_form.showFormError(msg)
          .always ->
            $card_submit.prop('disabled', false)
      false

  $('#register_broker_form').each ->
    $broker_form = $(@)
    $broker_form.on 'ajax:success', (e, data) ->
      $broker_form.closest('.wizard-step').slideUp(200)
      .parent().append(data.next_steps)
      $deal_step = $('#deal_step')
      $deal_step.hide().slideDown(200)
      .find('button').click ->
        if $('input[type=checkbox]', $deal_step).is(':checked')
          $deal_step.slideUp()
          $('#card_step').removeClass('hidden').hide().slideDown(200)
          $('#stripe_card_form').stripeCardForm ($form, data) ->
            $form.closest('.wizard-step').slideUp(200)
            $('#thank_you_step').removeClass('hidden').hide().slideDown(200)
        else
          $deal_step.find('form').showFormError('You must agree with terms and conditions')

  $('#update_charges_card').each ->
    $wraper = $(@)
    $('#stripe_card_form').stripeCardForm ($form, data) ->
      $('.alert', $form).remove()
      $form.get(0).reset()
      $wraper.each(-> $('p', @).remove()).prepend(data.card_info)
