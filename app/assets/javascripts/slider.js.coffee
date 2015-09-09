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

    changeSliderValue = ($slider, handleIndex=0) ->
      value = $slider.slider('values', handleIndex)
      selector = if handleIndex == 0 then 'min' else 'max'
      if value == $slider.data(selector)
        html = ''
      else
        value = Math.floor(convertValue(value, $slider))
        html = value + ' ' + ($slider.data('unit') || '')

      $sliderContainer = $slider.parent()

      $sliderContainer.find('.' + selector + '-label')
      .html(html)
      .position
          my: 'center top'
          at: 'center bottom'
          of: $sliderContainer.find('.ui-slider-handle:eq(' + handleIndex + ')')
          collision: 'flip none'
          offset: "0, 10"

      updateValues($slider)

    window.alignSliderLabelPosition = ($item) ->
      for i in [0, 1]
        changeSliderValue($item, i)

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
            changeSliderValue($this, $(ui.handle).data('uiSliderHandleIndex'))
          setTimeout(delay, 5)

    $('select[name="length_unit"]').change (e)=>
      unit = $(e.currentTarget).val()
      $('select[name="length_unit"]').select2('val', unit)
      $('[data-slide-name="length"]').each ->
        $slider = $(this)
        $slider.data('unit', unit)
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
        alignSliderLabelPosition($slider)
      $('[data-attr-name="price"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        if price = $boat.data('price')
          p = Number(@convertCurrency(price).toFixed(2))
          $boat.find('[data-attr-name="price"]').html(currency + ' ' + $.numberWithCommas(p))
