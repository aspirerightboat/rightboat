$ ->
  if $('.boat-form').length
    $('#manufacturer_picker, #model_picker').each ->
      $sel = $(@)
      collection = $sel.data('collection')
      url = '/search/' + collection
      $sel.selectize
        valueField: 'id',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        closeAfterSelect: true,
        createOnBlur: true,
        preload: 'focus',
        maxItems: 1,
#        options: $sel.data('initial-options') || [],
        load: (query, callback) ->
          makerId = $('#manufacturer_picker').val()
          if collection == 'models' && makerId && makerId.match(/^create:/)
            callback()
          data = {q: query}
          data.manufacturer_ids = makerId if collection == 'models'
          $.getJSON url, data, (res) ->
            callback(res[collection])
          .fail ->
            callback()
        create: (input) ->
          console.log('create', input)
          name: input,
          id: 'create:' + input
        onChange: (value) ->
          makerId = $('#manufacturer_picker').val()
          modelId = $('#model_picker').val()
          if makerId && makerId.match(/^\d+$/) && modelId && modelId.match(/^\d+$/)
            loadTemplate(makerId, modelId)

    loadTemplate = (makerId, modelId) ->
      $.getJSON '/broker-area/my-boats/find_template', manufacturer_id: makerId, model_id: modelId, (data) ->
        tryUpdateInputData('boat_type', data.boat_type_id)
        tryUpdateInputData('boat_length_m', data.length_m)
        tryUpdateInputData('spec_beam_m', data.specs.beam_m)
        tryUpdateInputData('spec_draft_min', data.specs.draft_min)
        tryUpdateInputData('spec_draft_max', data.specs.draft_max)
        tryUpdateInputData('spec_keel', data.specs.keel)
        tryUpdateInputData('price_amount', parseInt(data.price))

    tryUpdateInputData = (id, data) ->
      $el = $('#' + id)
      valueBlank = if $el.attr('type') == 'number' then !parseInt($el.val()) else !$el.val()
      if valueBlank && data
        if $el.data('selectize')
          $el.data('selectize').setValue(data)
        else if $el
          $el.val(data).change()

    $('.creatable-select').each ->
      $(@).selectize
        create: true,
        sortField: 'text'

    $('#boat_poa').each ->
      $poa = $(@)
      poaClick = -> $('#price_amount, #price_currency, #vat_included').prop('disabled', $poa.prop('checked'))
      $poa.click(poaClick)
      poaClick()

    feet2metres = (feet, inches) ->
      val = (feet + (inches/12))*0.3048
      Math.round(val*100)/100

    metres2feet = (metres) ->
      feet = metres*3.2808399
      inches = (feet-parseInt(feet))*12
      [parseInt(feet), parseInt(inches)]

    $('.m-ft-field').each ->
      $mInput = $('.m-input', @)
      $ftInput = $('.ft-input', @)
      $inInput = $('.in-input', @)
      $ftInInputs = $ftInput.add($inInput)

      mInputChanged = ->
        m = parseFloat($mInput.val())
        res = if m then metres2feet(m) else ['', '']
        $ftInput.val(res[0])
        $inInput.val(res[1])
      $mInput.change(mInputChanged).keyup(mInputChanged).mouseup(mInputChanged)
      mInputChanged()

      ftInInputsChanged = ->
        feet = parseInt($ftInput.val())
        inch = parseInt($inInput.val())
        res = if feet || inch then feet2metres(feet || 0, inch || 0) else ''
        $mInput.val(res)
      $ftInInputs.change(ftInInputsChanged).keyup(ftInInputsChanged).mouseup(mInputChanged)

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
