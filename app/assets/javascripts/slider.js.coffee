$ ->
  $(document).ready ->
    @convertCurrency = (value) ->
      currency = $('form:visible select[name="currency"]').val()
      rate = window.currencyRates[currency]
      rate * value

    @convertLength = (value) ->
      unit = $('form:visible select[name="length_unit"]').val()
      if unit == 'ft'
        return value * 3.28084
      else
        return value

    convertValue = (v, $item) =>
      convertFuncName = $item.data('convert')
      return v unless convertFuncName
      @[convertFuncName](v)

    window.alignSliderLabelPosition = ($item) ->
      $sliderContainer = $item.parent()

      v1 = $item.slider('values', 0)
      if v1 == $item.data('min')
        html1 = ''
      else
        v1 = Math.floor(convertValue(v1, $item))
        html1 = v1 + ' ' + ($item.data('unit') || '')

      v2 = $item.slider('values', 1)
      if v2 == $item.data('max')
        html2 = ''
      else
        v2 = Math.ceil(convertValue(v2, $item))
        html2 = v2 + ' ' + ($item.data('unit') || '')

      $sliderContainer.find('.min-label')
      .html(html1)
      .position
          my: 'center top'
          at: 'center bottom'
          of: $sliderContainer.find('.ui-slider-handle:eq(0)')
          collision: 'flip none'
          offset: '0, 10'

      $sliderContainer.find('.max-label')
      .html(html2)
      .position
          my: 'center top'
          at: 'center bottom'
          of: $sliderContainer.find('.ui-slider-handle:eq(1)')
          collision: 'flip none'
          offset: '0, 10'

    updateValues = ($slider) ->
      input_name = $slider.data('input')
      if input_name && input_name.length
        min = $slider.data('min')
        max = $slider.data('max')
        min_v = $slider.slider('values', 0)
        max_v = $slider.slider('values', 1)
        min_v = if min == min_v then '' else Math.floor(convertValue(min_v, $slider))
        max_v = if max == max_v then '' else Math.floor(convertValue(max_v, $slider))
        max_v = '' if max == max_v
        $('input[name="' + input_name + '_min"]').val(min_v)
        $('input[name="' + input_name + '_max"]').val(max_v)

    $( '.slider' ).each ->
      $sliderContainer = $(this).parent()
      $this = $(this)

      v1 = $this.data('value1')
      v2 = $this.data('value2')

      $this.slider
        range: true
        min: $this.data('min')
        max: $this.data('max')
        values: [ v1, v2 ]
        slide: ( event, ui ) ->
          delay = ->
            handleIndex = $(ui.handle).data('uiSliderHandleIndex')
            if handleIndex == 0
              label = '.min-label'
              value = Math.floor(convertValue(ui.value, $this))
            else
              label = '.max-label'
              value = Math.ceil(convertValue(ui.value, $this))

            $sliderContainer.find(label)
            .html(value + ' ' + ($this.data('unit') || ''))
            .position
              my: 'center top'
              at: 'center bottom'
              of: ui.handle
              collision: 'flip none'
              offset: "0, 10"
            updateValues($this)

          setTimeout(delay, 5)

      alignSliderLabelPosition($this)

    $('select[name="length_unit"]').change (e)=>
      unit = $(e.currentTarget).val()
      $('select[name="length_unit"]').select2('val', unit)
      $('[data-slide-name="length"]').each ->
        $slider = $(this)
        $slider.data('unit', unit)
        updateValues($slider)
        alignSliderLabelPosition($slider)
      $('[data-attr-name="loa"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        l = Number(@convertLength($boat.data('length')).toFixed(2))
        $boat.find('[data-attr-name="loa"]').html('' + l + ' ' + unit)

    $('select[name="currency"]').change (e)=>
      $el = $(e.currentTarget)
      currency = $el.find('option:selected').text()
      $('select[name="currency"]').select2('val', $el.val())
      $('[data-slide-name="price"]').each ->
        $slider = $(this)
        updateValues($slider)
        alignSliderLabelPosition($slider)
      $('[data-attr-name="price"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        if price = $boat.data('price')
          p = Number(@convertCurrency(price).toFixed(2))
          $boat.find('[data-attr-name="price"]').html(currency + ' ' + $.numberWithCommas(p))

