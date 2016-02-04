$ ->
  if $('.edit-boat-form').length
    #==> poa click
    poa_click = -> $('.boat-price-wrap').find('input, select').prop('disabled', $('#boat_poa').prop('checked'))
    $("#boat_poa").click(poa_click)
    poa_click()

    #==> meters-feets fields
    feet2metres = (feet, inches) ->
      val = (feet + (inches/12))*0.3048
      Math.round(val*100)/100

    metres2feet = (metres) ->
      feet = metres*3.2808399
      inches = (feet-parseInt(feet))*12
      [parseInt(feet), parseInt(inches)]

    $('.m-ft-field').each ->
      $m_input = $('.m-input', @)
      $ft_input = $('.ft-input', @)
      $in_input = $('.in-input', @)
      $ft_in_inputs = $ft_input.add($in_input)

      $m_input.change ->
        m = parseFloat(@value)
        res = if m then metres2feet(m) else ['', '']
        $ft_input.val(res[0])
        $in_input.val(res[1])
      $m_input.change()

      $ft_in_inputs.change ->
        feet = parseInt($ft_input.val())
        inch = parseInt($in_input.val())
        res = if feet || inch then feet2metres(feet || 0, inch|| 0) else ''
        $m_input.val(res)

    #==> unit fields
    $('.unit-field').each ->
      $hidden = $('input[type=hidden]', @)
      $amount_input = $('.amount-input', @)
      $unit_select = $('.unit-select', @)


      $amount_input.add($unit_select).change ->
        amount = parseFloat($amount_input.val())
        if amount
          unit = $unit_select.val()
          res = amount + ' ' + unit
        $hidden.val(res)
      $amount_input.change()
