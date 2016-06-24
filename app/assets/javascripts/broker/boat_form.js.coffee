$ ->
  if $('.boat-form').length
    $makerInput = $('#manufacturer_picker')
    $modelInput = $('#model_picker')
    $makerInput.add($modelInput).each ->
      $input = $(@)
      collection = $input.data('collection')
      url = '/search/' + collection
      $input.selectize
        valueField: 'name',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        closeAfterSelect: true,
        create: true,
        createOnBlur: true,
        preload: 'focus',
        maxItems: 1,
        options: if $input.val() then [{name: $input.val()}] else [],
        load: (query, callback) ->
#          console.log('load', collection)
          maker = $makerInput.val()
          data = {q: query}
          data.manufacturer = maker if collection == 'models'
          $.getJSON url, data, (res) ->
#            console.log('getJSON', res)
            callback(res[collection])
          .fail ->
#            console.log('fail')
            callback()
        onChange: (value) ->
          if collection == 'manufacturers'
            sel = $modelInput.data('selectize')
            sel.clearOptions()
            sel.clear()
            return
          maker = $makerInput.val()
          model = $modelInput.val()
          if maker && model
#            console.log('loadTemplate', maker, model)
            loadTemplate(maker, model)

    loadTemplate = (maker, model) ->
      $.ajax
        dataType: "json"
        url: '/broker-area/my-boats/find_template',
        data: {manufacturer: maker, model: model},
        beforeSend: -> $('#makemodel_wait').addClass('loading')
        complete: -> $('#makemodel_wait').removeClass('loading')
        success: (data) ->
          return if $.isEmptyObject(data)
          tryUpdateInputData('boat_type', data.boat_type, true)
          tryUpdateInputData('length_m', data.length_m)
          tryUpdateInputData('beam_m', data.specs.beam_m)
          tryUpdateInputData('draft_min', data.specs.draft_min)
          tryUpdateInputData('draft_max', data.specs.draft_max)
          tryUpdateInputData('keel_type', data.specs.keel_type, true)
          tryUpdateInputData('hull_material', data.specs.hull_material, true)
          tryUpdateInputData('engine_count', data.specs.engine_count)
          tryUpdateInputData('cabins_count', data.specs.cabins_count)
          tryUpdateInputData('berths_count', data.specs.berths_count)
          tryUpdateInputData('price_amount', parseInt(data.price))
          tryUpdateInputData('year_built', data.year_built)
          tryUpdateInputData('engine_make', data.engine_manufacturer, true)
          tryUpdateInputData('engine_model', data.engine_model, true)

    tryUpdateInputData = (id, data, addAndSelect = false) ->
      $input = $('#' + id)
      valueBlank = if $input.attr('type') == 'number' then !parseInt($input.val()) else !$input.val()
      if valueBlank && data
#        console.log('tryUpdateInputData', id, data)
        if (sel = $input.data('selectize'))
          if addAndSelect
            sel.addOption(name: data)
          sel.setValue(data)
        else
          $input.val(data).change()

#    $('.creatable-select').each ->
#      $(@).selectize
#        create: true,
#        sortField: 'text'

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
        else
          res = ''
        $hidden.val(res)
      $amount_input.change()

    $('.collection-select').each ->
      $input = $(@)
      collection = $input.data('collection')
      url = '/search/' + collection
      $input.selectize
        valueField: 'name',
        labelField: 'name',
        searchField: 'name',
        openOnFocus: true,
        closeAfterSelect: true,
        create: !!$input.data('create'),
        createOnBlur: !!$input.data('create'),
        preload: 'focus',
        maxItems: 1,
        options: if $input.val() then [{name: $input.val()}] else [],
        load: (query, callback) ->
          $.getJSON url, {q: query}, (data) ->
            callback(data.items)
          .fail ->
            callback()

    $('.images-dropzone').each ->
      $dropzone = $(@)
      $dropzone.dropzone
        url: $dropzone.data('upload-url'),
        maxFilesize: 5, # megabytes
        addRemoveLinks: true,
        removedfile: (a, b, c) -> console.log('removedfile', a, b, c)

      if window.boatImages.length
        $dropzone.addClass('dz-started')
        t = $('#dropzone_template').html()
        $.each window.boatImages, ->
          cap = @caption || ''
          $(t).appendTo($dropzone)
            .find('[data-dz-thumbnail]').attr('alt', cap).attr('src', @url).end()
            .find('[data-dz-size]').css(visibility: 'hidden').end()
            .find('[data-dz-name]').each(-> if cap then $(@).text(cap) else $(@).css(visibility: 'hidden')).end()
            .append($('<a/>').addClass('dz-remove').attr('href', 'javascript:undefined;').text('Remove file'))
            .addClass('dz-complete')
