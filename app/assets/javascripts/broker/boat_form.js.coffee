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
          maker = $makerInput.val()
          data = {q: query}
          data.manufacturer = maker if collection == 'models'
          $.getJSON url, data, (res) ->
            callback(res[collection])
          .fail ->
            callback()
        onChange: (value) ->
          if collection == 'manufacturers'
            sel = $modelInput.data('selectize')
            sel.clearOptions()
            return
          maker = $makerInput.val()
          model = $modelInput.val()
          if maker && model
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
          tryUpdateInputData('price_amount', parseInt(data.price))
          tryUpdateInputData('year_built', data.year_built)
          tryUpdateInputData('engine_manufacturer', data.engine_manufacturer, true)
          tryUpdateInputData('engine_model', data.engine_model, true)
          tryUpdateInputData('drive_type', data.drive_type, true)
          $.each data.specs, (name, value) ->
            addAndSelect = /^keel_type$|^hull_material$/.test(name)
            tryUpdateInputData(name, value, addAndSelect)

    tryUpdateInputData = (id, data, addAndSelect = false) ->
      # console.log('tryUpdateInputData', id, data, addAndSelect)
      if data
        if ($input = $('#' + id)).length
          if (valueBlank = if $input.attr('type') == 'number' then !parseInt($input.val()) else !$input.val())
            if (sel = $input.data('selectize'))
              if addAndSelect
                sel.addOption(name: data)
              sel.setValue(data)
            else
              $input.val(data).change()

    $('#boat_poa').each ->
      $poa = $(@)
      poaClick = ->
        checked = $poa.prop('checked')
        $('#price_amount, #vat_included').prop('disabled', checked)
        sel = $('#price_currency').data('selectize')
        if checked then sel.lock() else sel.unlock()

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
          params = {q: query}
          if $input.data('include-param')
            $el = $($input.data('include-param'))
            params[$el.attr('id')] = $el.val()
          $.getJSON url, params, (data) ->
            callback(data.items)
          .fail ->
            callback()

      $input.change ->
        if $input.data('onchange-clear') && ($dep = $($input.data('onchange-clear'))).length
          sel = $dep.data('selectize')
          sel.clearOptions()


    $('.images-dropzone').each ->
      $dropzone = $(@)
      dz = new Dropzone @, {
        url: $dropzone.data('upload-url'),
        addRemoveLinks: true,
        removedfile: ((file) ->
          console.log('removedfile', file)
        ),
        init: (->
          @.on 'success', (file, responseText) ->
            # TODO: receive image id from responseText and handle remove link
            console.log(file, responseText, $('.dz-remove', file.previewElement))

            #file.previewTemplate.appendChild(document.createTextNode(responseText));
        )
      }

      if window.boatImages.length
        $.each window.boatImages, ->
          # see: https://github.com/enyo/dropzone/wiki/FAQ#how-to-show-files-already-stored-on-server
          file = {name: @name, size: 0}
          dz.emit('addedfile', file)
          dz.emit('thumbnail', file, @url)
          dz.emit('complete', file)
          # TODO: handle remove link
          console.log(@id, $('.dz-remove', file.previewElement))
#          $(t).appendTo($dropzone)
#            .find('[data-dz-thumbnail]').attr('alt', cap).attr('src', @url).end()
#            .find('[data-dz-size]').css(visibility: 'hidden').end()
#            .find('[data-dz-name]').each(-> if cap then $(@).text(cap) else $(@).css(visibility: 'hidden')).end()
#            .append($('<a/>').addClass('dz-remove').attr('href', 'javascript:undefined;').text('Remove file'))
#            .addClass('dz-complete')

    $('[data-textarea-counter]').each ->
      $area = $(@)
      maxLen = parseInt($area.attr('maxlength'))
      $counter = $($area.data('textarea-counter'))
      $area.keyup ->
        $counter.text(maxLen - $area.val().length)
      .keyup()

    $('.checkable-label').each ->
      $el = $(@)
      $field = $($el.data('focus-field'))
      $check = $el.parent().find('input[type=checkbox]')
      oldVal = $field.val()
      $check.change ->
        if @checked
          if $field.val() == '' then $field.val(oldVal || 'Yes')
          $field[0].setSelectionRange(0, $field.val().length)
        else
          if $field.val() != '' then oldVal = $field.val(); $field.val('')
        $field.focus()

      updCheck = ->
        $check.prop('checked', $field.val() != '')
      $field.keyup ->
        updCheck()

      updCheck()

